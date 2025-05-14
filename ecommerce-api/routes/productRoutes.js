const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');

router.get('/categories', productController.getAllCategories);
router.get('/categories/:categoryName/products', productController.getProductsByCategory);
router.get('/search', productController.searchProducts);

module.exports = router;

