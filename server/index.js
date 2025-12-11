import express from "express";
import cors from "cors";
import fs from "fs";

const app = express();
app.use(cors());

app.get("/cameras", (req, res) => {
  const file = fs.readFileSync("./data/cameras.json", "utf8");
  res.json(JSON.parse(file));
});

app.listen(8080, () =>
  console.log("Fake Camera API running at http://localhost:8080")
);

