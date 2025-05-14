const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});
pool.connect()
  .then(() => console.log('Kết nối đến PostgreSQL thành công'))
  .catch((err) => console.error('Kết nối thất bại', err));

module.exports = pool;
