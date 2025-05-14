const express = require('express');
const app = express();
const productRoutes = require('./routes/productRoutes');
const orderRoutes = require('./routes/orderRoutes');

app.use(express.json());

app.use('/api/products', productRoutes);
app.use('/api', orderRoutes);

module.exports = app;

