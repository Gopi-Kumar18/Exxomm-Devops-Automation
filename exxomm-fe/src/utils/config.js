
const devConfig = {
  // This will be used for your local "npm start"
  // It relies on the Vite proxy in vite.config.js
  baseURL: import.meta.env.VITE_API_URL, 
};

const prodConfig = {
  // This will be used in your "docker build"
  // It relies on the Nginx proxy in nginx.conf
  baseURL: "", 
};

// This line automatically chooses the right config:
export const config = import.meta.env.PROD ? prodConfig : devConfig;

// This will log the correct URL in both environments
console.log(
  `Running in ${import.meta.env.PROD ? "production" : "development"} mode.`
);
console.log("API URL PRINTING:", config.baseURL);
