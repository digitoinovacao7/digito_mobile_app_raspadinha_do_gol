import { useState, useEffect } from "react";
import { collection, query, getDocs } from "firebase/firestore";
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
        const q = query(collection(db, "sponsors"));
        const snapshot = await getDocs(q);
        const list: Sponsor[] = [];
        snapshot.forEach((doc) => {
          const data = doc.data();
          if (data.active === true || data.active === undefined) {
            list.push({
              id: doc.id,
              name: data.name || "",
              logoUrl: data.logoUrl || data.image_url || "",
              siteUrl: data.siteUrl || data.site_url || "",
              order: Number(data.order ?? 0),
            });
          }
        });
        list.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
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

  // Duplica a lista de patrocinadores para criar o efeito infinito contínuo e suave
  const marqueeList = sponsors.length > 0 ? [...sponsors, ...sponsors, ...sponsors, ...sponsors] : [];

  return (
    <section className="w-full bg-slate-900/90 border-y border-slate-800 py-6 px-0 text-center overflow-hidden relative">
      {/* Sombra de gradiente suave nas bordas laterais */}
      <div className="absolute left-0 top-0 bottom-0 w-16 bg-gradient-to-r from-slate-900 to-transparent z-10 pointer-events-none" />
      <div className="absolute right-0 top-0 bottom-0 w-16 bg-gradient-to-l from-slate-900 to-transparent z-10 pointer-events-none" />

      <div className="w-full">
        <span className="text-xs font-bold text-amber-400 uppercase tracking-widest block mb-4">
          🤝 Patrocinadores & Parceiros Oficiais
        </span>
        <div className="overflow-hidden w-full flex">
          <div className="animate-marquee gap-6 md:gap-8 pr-6 md:pr-8">
            {marqueeList.map((sponsor, index) => {
              const content = (
                <div className="bg-white border border-slate-200 hover:border-amber-400 px-6 py-4 rounded-2xl flex items-center justify-center min-w-[170px] h-20 transition-all transform hover:scale-105 shadow-md hover:shadow-[0_0_25px_rgba(251,191,36,0.5)] group">
                  {sponsor.logoUrl ? (
                    <img
                      src={sponsor.logoUrl}
                      alt={sponsor.name}
                      className="max-h-12 max-w-[140px] object-contain transition-all duration-300 group-hover:scale-105"
                    />
                  ) : (
                    <span className="text-slate-900 font-black text-base group-hover:text-amber-600 transition-colors uppercase tracking-wide">
                      {sponsor.name}
                    </span>
                  )}
                </div>
              );

              if (sponsor.siteUrl && sponsor.siteUrl.trim().length > 0) {
                return (
                  <a
                    key={`${sponsor.id}-${index}`}
                    href={sponsor.siteUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    title={sponsor.name}
                    className="flex-shrink-0"
                  >
                    {content}
                  </a>
                );
              }

              return (
                <div key={`${sponsor.id}-${index}`} className="flex-shrink-0">
                  {content}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
