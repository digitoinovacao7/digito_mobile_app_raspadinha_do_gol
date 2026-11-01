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
    <section className="w-full bg-[#062414]/90 border-y border-emerald-800/60 py-4 px-4 text-center">
      <div className="max-w-6xl mx-auto">
        <span className="text-xs font-bold text-amber-400 uppercase tracking-widest block mb-2">
          🤝 Patrocinadores & Parceiros Oficiais
        </span>
        <div className="flex flex-wrap items-center justify-center gap-6 md:gap-8">
          {sponsors.map((sponsor) => (
            <SponsorItem key={sponsor.id} sponsor={sponsor} />
          ))}
        </div>
      </div>
    </section>
  );
}

function SponsorItem({ sponsor }: { sponsor: Sponsor }) {
  const [imgError, setImgError] = useState(false);

  const content = (
    <div className="bg-white border border-gray-100 hover:border-amber-400 p-3.5 rounded-2xl flex flex-col items-center justify-center min-w-[170px] max-w-[200px] transition-all duration-300 transform hover:scale-105 shadow-md hover:shadow-xl group cursor-pointer">
      <div className="bg-gray-50 rounded-xl p-2.5 w-full h-20 flex items-center justify-center border border-gray-100 overflow-hidden">
        {sponsor.logoUrl && !imgError ? (
          <img
            src={sponsor.logoUrl}
            alt={`Logo do patrocinador oficial ${sponsor.name}`}
            loading="lazy"
            onError={() => setImgError(true)}
            className="max-h-14 max-w-[140px] object-contain transition-transform duration-300 group-hover:scale-105"
          />
        ) : (
          <div className="flex items-center justify-center w-full h-full bg-emerald-50 rounded-lg border border-emerald-100">
            <span className="text-emerald-950 font-black text-sm uppercase tracking-wide text-center px-2">
              {sponsor.name}
            </span>
          </div>
        )}
      </div>
      <span className="text-xs font-bold text-gray-900 mt-2.5 text-center truncate max-w-[150px] group-hover:text-amber-600 transition-colors uppercase tracking-wider">
        {sponsor.name}
      </span>
    </div>
  );

  if (sponsor.siteUrl && sponsor.siteUrl.trim().length > 0) {
    return (
      <a
        href={sponsor.siteUrl}
        target="_blank"
        rel="noopener noreferrer"
        title={sponsor.name}
      >
        {content}
      </a>
    );
  }

  return <div>{content}</div>;
}
