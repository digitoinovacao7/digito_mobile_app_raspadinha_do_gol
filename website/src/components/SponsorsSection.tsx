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

  return (
    <section className="w-full bg-slate-900/90 border-y border-slate-800 py-8 px-4 text-center">
      <div className="max-w-6xl mx-auto">
        <span className="text-xs font-bold text-amber-400 uppercase tracking-widest block mb-4">
          🤝 Patrocinadores & Parceiros Oficiais
        </span>
        <div className="flex flex-wrap items-center justify-center gap-6 md:gap-8">
          {sponsors.map((sponsor) => {
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
