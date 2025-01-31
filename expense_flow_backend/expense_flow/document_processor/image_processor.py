import cv2
import numpy as np
import os
from typing import Tuple

class ImagePreprocessor:
    def __init__(self, max_size_mb: int = 3):
        self.max_size_mb = max_size_mb

    def process(self, image_path: str) -> Tuple[str, bool]:
        try:
            processed_path = self._get_processed_path(image_path)
            image = self._load_image(image_path)
            image = self._resize_image(image)
            
            cv2.imwrite(processed_path, image)
            
            if os.path.getsize(processed_path) / (1024 * 1024) > self.max_size_mb:
                raise ValueError(f"Processed image exceeds {self.max_size_mb}MB limit")
                
            return processed_path, True
            
        except Exception as e:
            print(f"Error preprocessing image: {str(e)}")
            return image_path, False

    def _get_processed_path(self, image_path: str) -> str:
        directory = os.path.dirname(image_path)
        filename = os.path.basename(image_path)
        name, ext = os.path.splitext(filename)
        return os.path.join(directory, f"{name}_processed{ext}")

    def _load_image(self, image_path: str) -> np.ndarray:
        image = cv2.imread(image_path)
        if image is None:
            raise ValueError("Failed to load image")
        return cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    def _resize_image(self, image: np.ndarray) -> np.ndarray:
        height, width = image.shape[:2]
        max_pixels = (self.max_size_mb * 1024 * 1024 * 8) / 24
        
        if height * width > max_pixels:
            scale = np.sqrt(max_pixels / (height * width))
            new_height = int(height * scale)
            new_width = int(width * scale)
            return cv2.resize(image, (new_width, new_height), interpolation=cv2.INTER_AREA)
        return image

    def _enhance_for_ocr(self, image: np.ndarray) -> np.ndarray:
        gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        thresh = cv2.adaptiveThreshold(
            gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2
        )
        denoised = cv2.fastNlMeansDenoising(thresh)
        
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
        enhanced = clahe.apply(denoised)
    
        return enhanced