from datetime import datetime
from decimal import Decimal

MOCK_RECEIPTS = {
    "smazalnia_receipt": {
        "id": "c8a8dc02-2830-4034-9146-c32877da5e2a",
        "merchant": {
            "name": "SMAŹALNIA",
            "address": "ul. KOŚCIUSZKI 1\n84-140 JASTARNIA"
        },
        "items": [
            {
                "description": "ZUPY",
                "quantity": 2.0,
                "total_price": "60.0",
                "category": "groceries"
            },
            {
                "description": "RYBY NA WAGĘ",
                "quantity": 1.0,
                "total_price": "138.0",
                "category": "groceries"
            },
            {
                "description": "FRYTKI/OPIEKANE",
                "quantity": 2.0,
                "total_price": "16.0",
                "category": "groceries"
            },
            {
                "description": "SURÓWKI",
                "quantity": 2.0,
                "total_price": "20.0",
                "category": "groceries"
            },
            {
                "description": "PIWO",
                "quantity": 1.0,
                "total_price": "9.0",
                "category": "alcoholic_beverages"
            },
            {
                "description": "SOK",
                "quantity": 1.0,
                "total_price": "8.0",
                "category": "groceries"
            }
        ],
        "total": "251.0",
        "transaction_datetime": "2020-06-13T12:59:00",
        "added_datetime": "2025-01-31T19:13:46.033396"
    },
    "lidl_receipt": {
        "id": "32fd4ae6-3a17-45a0-a96f-ec517000b870",
        "merchant": {
            "name": "Lidi sp. z o. o. sp. k.",
            "address": "86-065 Lisi Ogon, ul. Wyczynowa 10"
        },
        "items": [
            {
                "description": "Coca Cola",
                "quantity": 1.0,
                "total_price": "17.94",
                "category": "groceries"
            },
            {
                "description": "OPUST Coca Cola",
                "quantity": 0.0,
                "total_price": "1.0",
                "category": "groceries"
            },
            {
                "description": "Tyskie piwo puszka",
                "quantity": 4.0,
                "total_price": "11.96",
                "category": "alcoholic_beverages"
            },
            {
                "description": "Reklamówka mała 80%",
                "quantity": 3.0,
                "total_price": "2.37",
                "category": "other"
            },
            {
                "description": "Seler luz",
                "quantity": 0.778,
                "total_price": "6.22",
                "category": "groceries"
            },
            {
                "description": "DR PEPPER Napój gaz.",
                "quantity": 2.0,
                "total_price": "5.78",
                "category": "groceries"
            },
            {
                "description": "Bertoncello Gnocchi",
                "quantity": 1.0,
                "total_price": "6.99",
                "category": "groceries"
            },
            {
                "description": "Mlekovita SerKasztel",
                "quantity": 1.0,
                "total_price": "12.99",
                "category": "groceries"
            },
            {
                "description": "Kiełbasa myśliwska",
                "quantity": 1.0,
                "total_price": "11.53",
                "category": "groceries"
            },
            {
                "description": "Kiełb.biała z szynki",
                "quantity": 1.0,
                "total_price": "12.59",
                "category": "groceries"
            },
            {
                "description": "Pierogi ruskie 400g",
                "quantity": 2.0,
                "total_price": "14.58",
                "category": "groceries"
            },
            {
                "description": "Barilla Pesto",
                "quantity": 1.0,
                "total_price": "14.99",
                "category": "groceries"
            },
            {
                "description": "Mięso woł. na gulasz",
                "quantity": 2.0,
                "total_price": "47.98",
                "category": "groceries"
            },
            {
                "description": "Sok tłocz. jabłko 1",
                "quantity": 2.0,
                "total_price": "11.58",
                "category": "groceries"
            },
            {
                "description": "Sushi Box",
                "quantity": 1.0,
                "total_price": "8.67",
                "category": "groceries"
            },
            {
                "description": "Groch łuskany",
                "quantity": 1.0,
                "total_price": "2.69",
                "category": "groceries"
            },
            {
                "description": "Polędwiczka wieprz.",
                "quantity": 0.542,
                "total_price": "18.96",
                "category": "groceries"
            },
            {
                "description": "Pietruszka luz",
                "quantity": 0.322,
                "total_price": "3.22",
                "category": "groceries"
            },
            {
                "description": "Marchew luz",
                "quantity": 0.626,
                "total_price": "2.5",
                "category": "groceries"
            },
            {
                "description": "Makaron Tagliatelle",
                "quantity": 1.0,
                "total_price": "4.99",
                "category": "groceries"
            },
            {
                "description": "Jaja w.wybieg Sudety",
                "quantity": 1.0,
                "total_price": "11.49",
                "category": "groceries"
            },
            {
                "description": "Por luz",
                "quantity": 0.379,
                "total_price": "5.68",
                "category": "groceries"
            },
            {
                "description": "Bajgiel z makiem",
                "quantity": 4.0,
                "total_price": "7.96",
                "category": "groceries"
            },
            {
                "description": "Bułka mleczna",
                "quantity": 4.0,
                "total_price": "5.0",
                "category": "groceries"
            },
            {
                "description": "Tortilla pszenna6szt",
                "quantity": 1.0,
                "total_price": "4.82",
                "category": "groceries"
            }
        ],
        "total": "236.54",
        "transaction_datetime": "2025-02-01T07:53:00",
        "added_datetime": "2025-02-01T13:14:06.846754"
    },
    "dino_receipt": {
        "id": "5a00eb3e-71ee-4939-9694-79e15f71b441",
        "merchant": {
            "name": "Dino Polska S.A.",
            "address": "ul. Ostrowska 122, 63-700 Krotoszyn\nul. Łochowska 33, 86-005 Białe Błota"
        },
        "items": [
            {
                "description": "KWIAT STORCZY 12CM B",
                "quantity": 0.0,
                "total_price": "43.99",
                "category": "household"
            }
        ],
        "total": "43.99",
        "transaction_datetime": "2025-02-01T10:20:00",
        "added_datetime": "2025-02-01T13:17:50.065654"
    },
    "niewiscin_receipt1": {
        "id": "879b8e13-5320-482a-93ee-0046ff488b36",
        "merchant": {
            "name": "\"NIEWIEŚCIN\" SP. Z O.O. SP.K",
            "address": "86-120 NIEWIEŚCIN 8\nSKLEP NR 38\n86-005 BIAŁE BŁOTA, UL.ALTANOWA 2A"
        },
        "items": [
            {
                "description": "ŻEB PIECZENIOWE W",
                "quantity": 0.366,
                "total_price": "7.68",
                "category": "groceries"
            }
        ],
        "total": "7.68",
        "transaction_datetime": "2025-01-29T15:41:00",
        "added_datetime": "2025-02-01T13:19:08.743290"
    },
    "niewiscin_receipt2": {
        "id": "e862c7de-639a-4734-b36e-bd239b226c62",
        "merchant": {
            "name": "\"NIEWIEŚCIN\" SP. Z O.O. SP.K",
            "address": "86-005 BIAŁE BŁOTA, UL.ALTANOWA 2A"
        },
        "items": [
            {
                "description": "FILET Z KURCZAKA",
                "quantity": 0.506,
                "total_price": "12.54",
                "category": "groceries"
            },
            {
                "description": "FILET Z KURCZAKA",
                "quantity": 0.506,
                "total_price": "-12.54",
                "category": "groceries"
            },
            {
                "description": "SZY KONSERWOWA W",
                "quantity": 0.232,
                "total_price": "8.97",
                "category": "groceries"
            },
            {
                "description": "KIE RZEŹNIKA W",
                "quantity": 0.258,
                "total_price": "11.09",
                "category": "groceries"
            },
            {
                "description": "KARKÓWKA BK OKAZJA",
                "quantity": 1.128,
                "total_price": "21.08",
                "category": "groceries"
            }
        ],
        "total": "41.14",
        "transaction_datetime": "2025-01-29T15:59:00",
        "added_datetime": "2025-02-01T13:22:09.335124"
    },
    "sowa_receipt1": {
        "id": "18de8c2a-fc1f-445e-9a72-5100ba15ed33",
        "merchant": {
            "name": "CUKIERNIA SOWA sp. z o.o.",
            "address": "ul. ks. Schulza 3\n85-315 Bydgoszcz"
        },
        "items": [
            {
                "description": "DROŻDŻÓWKA Z KRUSZONKĄ. (W)",
                "quantity": 1.0,
                "total_price": "5.9",
                "category": "groceries"
            },
            {
                "description": "ROGAL BYDGOSKI .. (W)",
                "quantity": 1.0,
                "total_price": "5.9",
                "category": "groceries"
            },
            {
                "description": "DROŻDŻÓWKA Z SEREM .. (W)",
                "quantity": 1.0,
                "total_price": "5.9",
                "category": "groceries"
            },
            {
                "description": "BUŁKA PSZENNA. (W)",
                "quantity": 2.0,
                "total_price": "1.8",
                "category": "groceries"
            }
        ],
        "total": "19.5",
        "transaction_datetime": "2025-01-30T09:48:00",
        "added_datetime": "2025-02-01T13:23:48.636638"
    },
    "butcher_receipt": {
        "id": "74a27e22-2b75-49ce-aa3f-e2a20d200e43",
        "merchant": {
            "name": "HONORATA KAPEL",
            "address": "86-005 BIAŁE BŁOTA UL.SZUBIŃSKA 12"
        },
        "items": [
            {
                "description": "FILET MORSZCZUK",
                "quantity": 0.0,
                "total_price": "29.44",
                "category": "groceries"
            },
            {
                "description": "PASZTETY",
                "quantity": 0.0,
                "total_price": "7.77",
                "category": "groceries"
            },
            {
                "description": "POLĘDWICE KROJONE",
                "quantity": 0.0,
                "total_price": "12.2",
                "category": "groceries"
            },
            {
                "description": "SALAMI",
                "quantity": 0.0,
                "total_price": "6.05",
                "category": "groceries"
            },
            {
                "description": "SZYNKI DROBIOWE",
                "quantity": 0.0,
                "total_price": "10.98",
                "category": "groceries"
            },
            {
                "description": "MIELONKA KONS.",
                "quantity": 0.0,
                "total_price": "6.9",
                "category": "groceries"
            },
            {
                "description": "MIELONKA KONS.",
                "quantity": 0.0,
                "total_price": "-6.9",
                "category": "groceries"
            },
            {
                "description": "BUŁKA TARTA",
                "quantity": 0.0,
                "total_price": "6.9",
                "category": "groceries"
            }
        ],
        "total": "73.34",
        "transaction_datetime": "2025-02-01T09:23:00",
        "added_datetime": "2025-02-01T13:24:50.970396"
    },
    "netto_receipt": {
        "id": "e98614d0-6f49-4fd8-a455-51d912fda279",
        "merchant": {
            "name": "NETTO SP. Z O.O",
            "address": "UL. ALTANOWA ZA\n86-005 BIAŁE BŁOTA"
        },
        "items": [
            {
                "description": "C_CEBULA DYMKA PĘCZ.",
                "quantity": 1.0,
                "total_price": "3.09",
                "category": "groceries"
            },
{
                "description": "C_MASŁO OSEŁ, 500G",
                "quantity": 1.0,
                "total_price": "24.99",
                "category": "groceries"
            },
            {
                "description": "C_PAP.SŁODK SZ 250 G",
                "quantity": 1.0,
                "total_price": "5.99",
                "category": "groceries"
            }
        ],
        "total": "34.07",
        "transaction_datetime": "2025-02-01T09:33:00",
        "added_datetime": "2025-02-01T13:26:31.564156"
    },
    "rossmann_receipt": {
        "id": "27a15c95-8964-4423-bf4f-4ddeb9387a4c",
        "merchant": {
            "name": "Rossmann SDP Sklep nr 920",
            "address": "ul. Szubińska 8\n86-005 Białe Błota"
        },
        "items": [
            {
                "description": "ISANA PŁATKI KOSMIAX",
                "quantity": 1.0,
                "total_price": "3.99",
                "category": "personal_care"
            },
            {
                "description": "SIDOLUX PŁYN DO MIAX",
                "quantity": 1.0,
                "total_price": "6.99",
                "category": "household"
            },
            {
                "description": "SYOSS SZAMPON KER\\AX",
                "quantity": 1.0,
                "total_price": "13.99",
                "category": "personal_care"
            }
        ],
        "total": "24.97",
        "transaction_datetime": "2025-02-01T09:28:00",
        "added_datetime": "2025-02-01T13:27:09.208923"
    },
    "netto_receipt2": {
        "id": "1fd95d07-add1-4de1-bb32-6e4c2d875c60",
        "merchant": {
            "name": "Netto Sp. z O. O.",
            "address": "Motanie 30, 73-108 Kobylanka"
        },
        "items": [
            {
                "description": "C_TWARÓG SERNIK. 1KG",
                "quantity": 1.0,
                "total_price": "16.99",
                "category": "groceries"
            },
            {
                "description": "C_SEREK WIEJSKI 180G",
                "quantity": 1.0,
                "total_price": "3.99",
                "category": "groceries"
            },
            {
                "description": "C_KUKU ZŁO 340/285 G",
                "quantity": 1.0,
                "total_price": "6.59",
                "category": "groceries"
            },
            {
                "description": "C_TWAROG TŁUS.250G",
                "quantity": 1.0,
                "total_price": "6.29",
                "category": "groceries"
            },
            {
                "description": "C_RYCKI MAASDAM 135G",
                "quantity": 1.0,
                "total_price": "6.39",
                "category": "groceries"
            },
            {
                "description": "C_POMARAŃCZE UKŁAD.",
                "quantity": 1.708,
                "total_price": "15.35",
                "category": "groceries"
            },
            {
                "description": "A_LUCKY STRIKE BLUE",
                "quantity": 2.0,
                "total_price": "43.98",
                "category": "other"
            }
        ],
        "total": "99.58",
        "transaction_datetime": "2025-01-29T16:56:00",
        "added_datetime": "2025-02-01T13:28:07.889566"
    },
    "lpp_receipt": {
        "id": "85c19578-e662-42ab-a4a8-1745445e793e",
        "merchant": {
            "name": "LPP S.A.",
            "address": "85-799 Bydgoszcz\nFordońska 141"
        },
        "items": [
            {
                "description": "STANIK DAMSKI",
                "quantity": 1.0,
                "total_price": "35.99",
                "category": "clothing"
            }
        ],
        "total": "35.99",
        "transaction_datetime": "2025-01-30T09:43:00",
        "added_datetime": "2025-02-01T13:28:40.344271"
    }
}

# Helper functions for testing
def get_receipts_by_category(category):
    """Get all items from receipts with specified category"""
    items = []
    for receipt in MOCK_RECEIPTS.values():
        for item in receipt['items']:
            if item['category'] == category:
                items.append(item)
    return items

def get_receipts_by_date_range(start_date, end_date):
    """Get all receipts within specified date range"""
    receipts = []
    for receipt in MOCK_RECEIPTS.values():
        receipt_date = datetime.fromisoformat(receipt['transaction_datetime'])
        if start_date <= receipt_date <= end_date:
            receipts.append(receipt)
    return receipts

def get_receipts_by_merchant(merchant_name):
    """Get all receipts from specified merchant"""
    return [
        receipt for receipt in MOCK_RECEIPTS.values()
        if merchant_name.lower() in receipt['merchant']['name'].lower()
    ]

def calculate_total_for_items(items):
    """Calculate total price for list of items"""
    return str(sum(Decimal(item['total_price']) for item in items))

# Test data constants
TEST_MERCHANTS = {
    'ROSSMANN': 'Rossmann SDP Sklep nr 920',
    'LIDL': 'Lidi sp. z o. o. sp. k.',
    'NETTO': 'NETTO SP. Z O.O',
    'SOWA': 'CUKIERNIA SOWA sp. z o.o.',
    'DINO': 'Dino Polska S.A.',
    'LPP': 'LPP S.A.'
}

TEST_DATES = {
    'START_DATE': datetime(2025, 1, 29),
    'END_DATE': datetime(2025, 2, 1),
    'SPECIFIC_DATE': datetime(2025, 2, 1, 9, 28)
}

TEST_CATEGORIES = [
    'groceries',
    'alcoholic_beverages',
    'personal_care',
    'household',
    'clothing',
    'other'
]