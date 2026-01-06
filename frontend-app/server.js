const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send(`
    <h1>🛒 Demo E-Commerce Store</h1>
    <ul>
      <li>Laptop – $999</li>
      <li>Phone – $599</li>
      <li>Headphones – $199</li>
    </ul>
    <a href="/checkout">Go to Checkout</a>
  `);
});

app.get("/checkout", (req, res) => {
  res.redirect("http://checkout:3000/");
});

app.listen(3000, () => {
  console.log("Frontend running on port 3000");
});

