from __future__ import annotations

import logging
import uuid
from collections import defaultdict
from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional, Tuple

from dateutil.relativedelta import relativedelta
from sqlalchemy import and_, func, select
from sqlalchemy.orm import selectinload

from expense_flow.api.models import (
    Category,
    CategoryItem,
    CategoryResponse,
    CategorySummary,
    CategoryWithItems,
    DailyExpense,
    Merchant,
    MonthSummary,
    MonthSummaryResponse,
    Receipt,
    ReceiptItem,
    SearchResult,
    SearchResultItem,
    get_category_icon,
    get_category_name,
)
from expense_flow.config import get_config
from expense_flow.db.models import ReceiptItemORM, ReceiptORM

from .base_repository import BaseRepository, DatabaseError, handle_db_errors

logger = logging.getLogger("expense_flow")


class ReceiptRepository(BaseRepository):
    """Repository responsible for CRUD and analytical queries on receipts."""

    def __init__(self, session):
        super().__init__(session)

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------
    def _map_receipt_model(self, model: ReceiptORM) -> Receipt:
        merchant = Merchant(
            name=model.merchant_name or "",
            address=model.merchant_address or "",
        )
        items = [
            ReceiptItem(
                description=item.description,
                quantity=item.quantity,
                total_price=Decimal(item.total_price),
                category=Category(item.category),
            )
            for item in model.items
        ]
        return Receipt(
            id=model.id,
            merchant=merchant,
            items=items,
            total=Decimal(model.total),
            transaction_datetime=model.transaction_datetime,
            added_datetime=model.added_datetime,
        )

    async def _fetch_receipt_with_items(self, receipt_id: str) -> ReceiptORM | None:
        stmt = (
            select(ReceiptORM)
            .options(selectinload(ReceiptORM.items))
            .where(ReceiptORM.id == receipt_id)
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    # ------------------------------------------------------------------
    # CRUD
    # ------------------------------------------------------------------
    @handle_db_errors
    async def insert_receipt(self, receipt: Receipt) -> str:
        receipt_id = receipt.id or str(uuid.uuid4())
        added_datetime = receipt.added_datetime or datetime.utcnow()

        model = ReceiptORM(
            id=receipt_id,
            merchant_name=receipt.merchant.name if receipt.merchant else "",
            merchant_address=receipt.merchant.address if receipt.merchant else "",
            total=receipt.total,
            transaction_datetime=receipt.transaction_datetime,
            added_datetime=added_datetime,
        )
        model.items = [
            ReceiptItemORM(
                description=item.description,
                quantity=item.quantity,
                total_price=item.total_price,
                category=item.category.value,
            )
            for item in receipt.items
        ]

        self.session.add(model)
        await self.session.commit()

        try:
            config = get_config()
            if getattr(config, "vector_db_path", None):
                from expense_flow.services.vector_store_service import VectorStoreService
                from expense_flow.services.database_sync_service import DatabaseSyncService

                vector_store = VectorStoreService(config)
                sync_service = DatabaseSyncService(vector_store, self)
                receipt_for_sync = receipt.copy(update={"id": receipt_id, "added_datetime": added_datetime})
                await sync_service.sync_receipt_items_async(receipt_for_sync)
        except Exception as exc:  # noqa: BLE001
            logger.warning("Vector store sync failed: %s", exc)

        return receipt_id

    @handle_db_errors
    async def get_receipt(self, receipt_id: str) -> Optional[Receipt]:
        model = await self._fetch_receipt_with_items(receipt_id)
        if not model:
            return None
        return self._map_receipt_model(model)

    @handle_db_errors
    async def get_receipts(self, page: int, page_size: int) -> List[Receipt]:
        skip = (page - 1) * page_size
        stmt = (
            select(ReceiptORM)
            .options(selectinload(ReceiptORM.items))
            .order_by(ReceiptORM.transaction_datetime.desc())
            .offset(skip)
            .limit(page_size)
        )
        result = await self.session.execute(stmt)
        return [self._map_receipt_model(model) for model in result.scalars().all()]

    @handle_db_errors
    async def get_receipt_count(self) -> int:
        stmt = select(func.count(ReceiptORM.id))
        result = await self.session.execute(stmt)
        return int(result.scalar_one())

    @handle_db_errors
    async def delete_receipt(self, receipt_id: str) -> bool:
        model = await self._fetch_receipt_with_items(receipt_id)
        if not model:
            return False

        await self.session.delete(model)
        await self.session.commit()

        try:
            config = get_config()
            if getattr(config, "vector_db_path", None):
                from expense_flow.services.vector_store_service import VectorStoreService
                from expense_flow.services.database_sync_service import DatabaseSyncService

                vector_store = VectorStoreService(config)
                sync_service = DatabaseSyncService(vector_store, self)
                await sync_service.remove_receipt_items_async(receipt_id)
        except Exception as exc:  # noqa: BLE001
            logger.warning("Vector store sync failed during deletion: %s", exc)

        return True

    @handle_db_errors
    async def update_receipt(self, receipt: Receipt) -> bool:
        model = await self._fetch_receipt_with_items(receipt.id)
        if not model:
            return False

        model.merchant_name = receipt.merchant.name if receipt.merchant else ""
        model.merchant_address = receipt.merchant.address if receipt.merchant else ""
        model.total = receipt.total
        model.transaction_datetime = receipt.transaction_datetime
        model.added_datetime = receipt.added_datetime or model.added_datetime

        model.items.clear()
        for item in receipt.items:
            model.items.append(
                ReceiptItemORM(
                    description=item.description,
                    quantity=item.quantity,
                    total_price=item.total_price,
                    category=item.category.value,
                )
            )

        await self.session.commit()

        try:
            config = get_config()
            if getattr(config, "vector_db_path", None):
                from expense_flow.services.vector_store_service import VectorStoreService
                from expense_flow.services.database_sync_service import DatabaseSyncService

                vector_store = VectorStoreService(config)
                sync_service = DatabaseSyncService(vector_store, self)
                await sync_service.remove_receipt_items_async(receipt.id)
                await sync_service.sync_receipt_items_async(receipt)
        except Exception as exc:  # noqa: BLE001
            logger.warning("Vector store sync failed during update: %s", exc)

        return True

    # ------------------------------------------------------------------
    # Aggregations & analytics
    # ------------------------------------------------------------------
    @handle_db_errors
    async def get_category_totals(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> Dict[Category, Decimal]:
        stmt = (
            select(ReceiptItemORM.category, func.sum(ReceiptItemORM.total_price))
            .join(ReceiptORM, ReceiptItemORM.receipt_id == ReceiptORM.id)
            .group_by(ReceiptItemORM.category)
        )
        if start_date:
            stmt = stmt.where(ReceiptORM.transaction_datetime >= start_date)
        if end_date:
            stmt = stmt.where(ReceiptORM.transaction_datetime <= end_date)

        result = await self.session.execute(stmt)

        totals: Dict[Category, Decimal] = defaultdict(lambda: Decimal("0"))
        for category_value, total_value in result.all():
            totals[Category(category_value)] += Decimal(total_value or 0)
        return totals

    @handle_db_errors
    async def get_categorized_items(
        self,
        category: Category,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> List[Dict[str, Any]]:
        stmt = (
            select(
                ReceiptItemORM.description,
                ReceiptItemORM.total_price,
                ReceiptItemORM.quantity,
            )
            .join(ReceiptORM, ReceiptItemORM.receipt_id == ReceiptORM.id)
            .where(ReceiptItemORM.category == category.value)
        )
        if start_date:
            stmt = stmt.where(ReceiptORM.transaction_datetime >= start_date)
        if end_date:
            stmt = stmt.where(ReceiptORM.transaction_datetime <= end_date)

        result = await self.session.execute(stmt)
        items: List[Dict[str, Any]] = []
        for description, total_price, quantity in result.all():
            items.append(
                {
                    "description": description,
                    "total_price": Decimal(total_price or 0),
                    "quantity": quantity or 0,
                }
            )
        return items

    @handle_db_errors
    async def get_daily_expenses(self, year: int, month: int) -> List[DailyExpense]:
        start_date = datetime(year, month, 1)
        if month == 12:
            end_date = datetime(year + 1, 1, 1)
        else:
            end_date = datetime(year, month + 1, 1)

        stmt = (
            select(
                func.strftime("%d", ReceiptORM.transaction_datetime).label("day"),
                func.max(ReceiptORM.transaction_datetime),
                func.sum(ReceiptORM.total),
            )
            .where(
                and_(
                    ReceiptORM.transaction_datetime >= start_date,
                    ReceiptORM.transaction_datetime < end_date,
                )
            )
            .group_by("day")
        )

        result = await self.session.execute(stmt)
        expenses = []
        for day_str, max_dt, total in result.all():
            day_int = int(day_str)
            expenses.append(
                DailyExpense(
                    day=day_int,
                    total=Decimal(total or 0),
                    transaction_datetime=max_dt,
                )
            )

        return sorted(expenses, key=lambda x: x.day)

    def _find_similar_description(
        self,
        normalized_desc: str,
        existing_descriptions: List[str],
        threshold: float = 0.95,
    ) -> Optional[str]:
        for existing in existing_descriptions:
            if self._are_similar(normalized_desc, existing, threshold):
                return existing
        return None

    def _get_current_month_range(self) -> Tuple[datetime, datetime]:
        current_month = datetime.utcnow().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        next_month = current_month + relativedelta(months=1)
        return current_month, next_month

    def _group_similar_items(self, items: List[Dict[str, Any]], category: Category) -> Dict[str, Dict[str, Any]]:
        grouped_items: Dict[str, Dict[str, Any]] = defaultdict(
            lambda: {"total": Decimal("0"), "count": Decimal("0"), "original_descriptions": set()}
        )
        known_descriptions: List[str] = []

        for item in items:
            original_desc = item["description"]
            normalized_desc = original_desc.lower().strip()

            matching_desc = self._find_similar_description(normalized_desc, known_descriptions)
            if matching_desc:
                group_key = matching_desc
            else:
                group_key = normalized_desc
                known_descriptions.append(normalized_desc)

            grouped_items[group_key]["total"] += Decimal(item["total_price"])
            grouped_items[group_key]["count"] += Decimal(item.get("quantity") or 0)
            grouped_items[group_key]["original_descriptions"].add(original_desc)

        return grouped_items

    def _convert_to_category_items(self, grouped_items: Dict[str, Dict[str, Any]], category: Category) -> List[CategoryItem]:
        category_items: List[CategoryItem] = []
        sorted_items = sorted(grouped_items.items(), key=lambda kv: kv[1]["total"], reverse=True)

        for idx, (_, data) in enumerate(sorted_items):
            display_name = min(data["original_descriptions"], key=len)
            category_items.append(
                CategoryItem(
                    id=f"{category.value}_{idx + 1}",
                    name=display_name,
                    amount=float(data["total"]),
                    count=int(data["count"]) if data["count"] else 0,
                )
            )

        if not category_items:
            category_items.append(
                CategoryItem(
                    id=f"{category.value}_1",
                    name="No items this month",
                    amount=0.0,
                    count=0,
                )
            )

        return category_items

    @handle_db_errors
    async def get_categories_with_items(self) -> CategoryResponse:
        current_month, next_month = self._get_current_month_range()
        categories: List[CategoryWithItems] = []

        for category in Category:
            items = await self.get_categorized_items(category, current_month, next_month)
            grouped_items = self._group_similar_items(items, category)
            category_items = self._convert_to_category_items(grouped_items, category)

            categories.append(
                CategoryWithItems(
                    id=category.value,
                    name=get_category_name(category),
                    iconName=get_category_icon(category),
                    items=category_items,
                )
            )

        return CategoryResponse(categories=categories)

    def _calculate_month_totals(self, rows: List[Tuple[str, str, Decimal]]) -> Dict[str, Dict[str, Decimal]]:
        totals: Dict[str, Dict[str, Decimal]] = defaultdict(lambda: defaultdict(lambda: Decimal("0")))
        for month_key, category_value, amount in rows:
            totals[month_key][category_value] += Decimal(amount or 0)
        return totals

    @handle_db_errors
    async def get_monthly_summaries(self) -> MonthSummaryResponse:
        stmt = (
            select(
                func.strftime("%Y-%m", ReceiptORM.transaction_datetime).label("month_key"),
                ReceiptItemORM.category,
                func.sum(ReceiptItemORM.total_price),
            )
            .join(ReceiptItemORM, ReceiptItemORM.receipt_id == ReceiptORM.id)
            .group_by("month_key", ReceiptItemORM.category)
        )

        result = await self.session.execute(stmt)
        rows = [(month_key, category_value, Decimal(total or 0)) for month_key, category_value, total in result.all()]
        month_totals = self._calculate_month_totals(rows)

        sorted_months = sorted(month_totals.keys(), reverse=True)
        summaries: List[MonthSummary] = []

        for index, month_key in enumerate(sorted_months):
            current_month_dt = datetime.strptime(month_key, "%Y-%m")
            prev_month_dt = current_month_dt - relativedelta(months=1)
            prev_month_key = prev_month_dt.strftime("%Y-%m")

            prev_totals = month_totals.get(prev_month_key, defaultdict(lambda: Decimal("0")))
            category_summaries = []
            for category in Category:
                current_amount = month_totals[month_key].get(category.value, Decimal("0"))
                previous_amount = prev_totals.get(category.value, Decimal("0"))
                category_summaries.append(
                    CategorySummary(
                        id=category.value,
                        name=get_category_name(category),
                        iconName=get_category_icon(category),
                        amount=float(current_amount),
                        previousMonthAmount=float(previous_amount),
                    )
                )

            previous_month_total = sum(prev_totals.values()) if prev_totals else Decimal("0")

            summaries.append(
                MonthSummary(
                    id=str(len(sorted_months) - index),
                    monthNumber=current_month_dt.month,
                    year=current_month_dt.year,
                    previousMonthTotal=float(previous_month_total),
                    categories=category_summaries,
                )
            )

        return MonthSummaryResponse(months=summaries)

    def _filter_items_by_categories(
        self,
        records: List[Tuple[str, Decimal, str]],
        categories: List[Category],
    ) -> Dict[str, Any]:
        matching_items = []
        total = Decimal("0")

        for description, total_price, category in records:
            matching_items.append(
                {
                    "description": description,
                    "total_price": str(total_price),
                    "category": category,
                }
            )
            total += Decimal(total_price)

        return {"items": matching_items, "total": str(total)}

    def _convert_to_search_result(self, records: List[Tuple[str, Decimal, str]]) -> Dict[str, Any]:
        total = Decimal("0")
        items = []
        for description, total_price, category in records:
            total += Decimal(total_price)
            items.append(
                {
                    "description": description,
                    "total_price": str(total_price),
                    "category": category,
                }
            )
        return {"items": items, "total": str(total)}

    @handle_db_errors
    async def search_receipts(
        self,
        merchant_name: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        categories: Optional[List[Category]] = None,
        item_description: Optional[str] = None,
    ) -> SearchResult:
        stmt = (
            select(
                ReceiptItemORM.description,
                ReceiptItemORM.total_price,
                ReceiptItemORM.category,
            )
            .join(ReceiptORM, ReceiptItemORM.receipt_id == ReceiptORM.id)
        )

        if merchant_name:
            stmt = stmt.where(func.lower(ReceiptORM.merchant_name).like(f"%{merchant_name.lower()}%"))
        if start_date:
            stmt = stmt.where(ReceiptORM.transaction_datetime >= start_date)
        if end_date:
            stmt = stmt.where(ReceiptORM.transaction_datetime <= end_date)
        if categories:
            category_values = [category.value for category in categories]
            stmt = stmt.where(ReceiptItemORM.category.in_(category_values))
        if item_description:
            stmt = stmt.where(func.lower(ReceiptItemORM.description).like(f"%{item_description.lower()}%"))

        result = await self.session.execute(stmt)
        records = [(desc, Decimal(total or 0), category) for desc, total, category in result.all()]

        if categories:
            data = self._filter_items_by_categories(records, categories)
        else:
            data = self._convert_to_search_result(records)

        return SearchResult(
            items=[SearchResultItem(**item) for item in data["items"]],
            total=data["total"],
        )

    @handle_db_errors
    async def get_all_receipts(self) -> List[Receipt]:
        stmt = select(ReceiptORM).options(selectinload(ReceiptORM.items))
        result = await self.session.execute(stmt)
        return [self._map_receipt_model(model) for model in result.scalars().all()]
