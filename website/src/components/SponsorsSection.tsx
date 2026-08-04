import { useState, useEffect } from "react";
import { collection, query, where, orderBy, getDocs } from "firebase/firestore";
import { db } from "../firebase";

interface Sponsor {
  id: string;
  name: string;
  logoUrl: string;
  siteUrl?: string;
  order?: number;
}

export function SponsorsSection() {
  const [sponsors, setSponsors] = useState<Sponsor[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function loadSponsors() {
      try {
        const q = query(
          collection(db, "sponsors"),
          where("active", "==", true),
          orderBy("order", "asc")
        );
        const snapshot = await getDocs(q);
        const list: Sponsor[] = [];
        snapshot.forEach((doc) => {
          const data = doc.data();
          list.push({
            id: doc.id,
            name: data.name || "",
            logoUrl: data.logoUrl || data.image_url || "",
            siteUrl: data.siteUrl || data.site_url || "",
            order: data.order ?? 0,
          });
        });
        setSponsors(list);
      } catch (err) {
        console.error("Erro ao carregar patrocinadores:", err);
      } finally {
        setIsLoading(false);
      }
    }

    loadSponsors();
  }, []);

  if (isLoading || sponsors.length === 0) {
    return null;
  }

  return (
    <section className="py-16 px-4 w-full bg-slate-900/90 border-t border-slate-800 text-center">
      <div className="max-w-6xl mx-auto">
        <span className="bg-amber-400/10 text-amber-400 border border-amber-400/30 text-xs font-bold px-4 py-1.5 rounded-full uppercase tracking-wider inline-block mb-3">
          Parceiros Oficiais
        </span>
        <h2 className="text-3xl md:text-4xl font-black text-white mb-3">
          Patrocinadores & Apoio
        </h2>
        <p className="text-gray-400 max-w-xl mx-auto mb-10 text-sm md:text-base">
          Marcas incríveis que acreditam na cultura do futebol e financiam as premiações dos torcedores.
        </p>

        <div className="flex flex-wrap items-center justify-center gap-8 md:gap-12">
          {sponsors.map((sponsor) => {
            const content = (
              <div className="bg-slate-950/60 border border-slate-800 hover:border-amber-400/50 p-6 rounded-2xl flex items-center justify-center w-44 h-24 transition-all transform hover:scale-105 hover:shadow-[0_0_25px_rgba(251,191,36,0.15)] group">
                {sponsor.logoUrl ? (
                  <img
                    src={sponsor.logoUrl}
                    alt={sponsor.name}
                    className="max-h-14 max-w-[130px] object-contain filter grayscale group-hover:grayscale-0 transition-all duration-300"
                  />
                ) : (
                  <span className="text-white font-bold text-lg group-hover:text-amber-400 transition-colors">
                    {sponsor.name}
                  </span>
                )}
              </div>
            );

            if (sponsor.siteUrl && sponsor.siteUrl.trim().length > 0) {
              return (
                <a
                  key={sponsor.id}
                  href={sponsor.siteUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  title={sponsor.name}
                >
                  {content}
                </a>
              );
            }

            return <div key={sponsor.id}>{content}</div>;
          })}
        </div>
      </div>
    </section>
  );
}
