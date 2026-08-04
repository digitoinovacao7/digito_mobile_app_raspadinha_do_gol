import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyBGzOetdqg0yYatDFhaJO6uqRiKKcyzhHc",
  authDomain: "raspadinhadogol.firebaseapp.com",
  projectId: "raspadinhadogol",
  storageBucket: "raspadinhadogol.firebasestorage.app",
  messagingSenderId: "882930210875",
  appId: "1:882930210875:web:13a47402546b833a6ba41e"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
