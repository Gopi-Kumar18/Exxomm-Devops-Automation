require('dotenv').config()

const mongoose = require('mongoose');

const connectDB = async () => {
  // Read the variables from .env
  const user = process.env.MONGO_USER;
  const pass = process.env.MONGO_PASS;
  const dbName = process.env.MONGO_DB_NAME;

  //for docker and local development
  // const uri = `mongodb://${user}:${pass}@mongo:27017/${dbName}?authSource=admin`;

  // // --- THIS IS THE LOGGING YOU ASKED FOR ---
  // console.log("-----------------------------------------");
  // console.log("ATTEMPTING DATABASE CONNECTION...");
  // console.log("Connecting with User:", user);
  // console.log("Connecting with Pass:", pass); // We hide most of the password
  // console.log("Connecting with DB:", dbName);
  // console.log("Full URI:", uri);
  // console.log("-----------------------------------------");
  // // --- END OF LOGGING ---



  //for production deployment on cloud services
    const uri = process.env.MONGO_URI;

  console.log("-----------------------------------------");
  console.log("ATTEMPTING PRODUCTION DATABASE CONNECTION...");
  console.log("Connecting with URI:", uri); // Log a preview
  console.log("-----------------------------------------");


  try {
    // Use the newly built URI
    const conn = await mongoose.connect(uri, {
      useUnifiedTopology: true,
      useNewUrlParser: true,
    });

    console.log(`MongoDB Connected Successfully: ${conn.connection.host}`);
  } catch (err) {
    // This will print the full error object
    console.error(`MongoDB connection FAIL : `, err);
    process.exit(1);
  }
};

module.exports = {connectDB};