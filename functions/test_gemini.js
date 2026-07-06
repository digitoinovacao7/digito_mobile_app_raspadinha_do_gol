const { GoogleGenAI, Type } = require("@google/genai");

async function run() {
    console.log("Type.OBJECT is:", Type ? Type.OBJECT : "undefined");
}
run().catch(console.error);
