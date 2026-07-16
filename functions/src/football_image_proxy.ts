import {onRequest} from "firebase-functions/v2/https";
import axios from "axios";

const ALLOWED_LOGO_HOSTS = new Set([
  "media.api-sports.io",
  "crests.football-data.org",
]);

export const proxyFootballImage = onRequest(
  {region: "southamerica-east1", cors: true},
  async (request, response) => {
    const rawUrl = request.query.url;
    if (typeof rawUrl !== "string") {
      response.status(400).send("URL da imagem não informada.");
      return;
    }

    let imageUrl: URL;
    try {
      imageUrl = new URL(rawUrl);
    } catch (_) {
      response.status(400).send("URL da imagem inválida.");
      return;
    }

    if (imageUrl.protocol !== "https:" || !ALLOWED_LOGO_HOSTS.has(imageUrl.hostname)) {
      response.status(403).send("Domínio de imagem não permitido.");
      return;
    }

    try {
      const upstream = await axios.get<ArrayBuffer>(imageUrl.toString(), {
        responseType: "arraybuffer",
        timeout: 10000,
        maxRedirects: 3,
      });

      response.set(
        "Content-Type",
        String(upstream.headers["content-type"] || "image/png"),
      );
      response.set("Cache-Control", "public, max-age=86400, s-maxage=604800");
      response.status(200).send(Buffer.from(upstream.data));
    } catch (error: any) {
      console.error("Football image proxy error:", error.response?.status || error.message);
      response.status(502).send("Não foi possível carregar a imagem.");
    }
  },
);
