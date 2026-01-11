const express = require("express");
const app = express();

const PORT = 80; // MUST be 80 inside container

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
  // Swarm service DNS, container port 80
  res.redirect("http://checkout/checkout");
});

app.listen(PORT, () => {
  console.log(`Frontend running on port ${PORT}`);
});

