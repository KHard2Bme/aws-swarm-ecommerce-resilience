const express = require("express");
const app = express();
const PORT = 80;

app.get("/checkout", (req, res) => {
  res.send("<h1>Checkout Page</h1><p>Cart details go here!</p>");
});

app.listen(PORT, () => {
  console.log(`Checkout running on port ${PORT}`);
});
