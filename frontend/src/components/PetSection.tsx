import { Cat, Dog } from "lucide-react";
import { useState } from "react";
import cats from "../data/cats.json";
import dogs from "../data/dogs.json";
import type { Pet } from "../types/Pet";
import { PetCard } from "./PetCard";

export const PetSection = () => {
  const sections: { title: string; data: Pet[] }[] = [
    { title: "Dogs", data: dogs },
    { title: "Cats", data: cats },
  ];

  const sectionIcons: Record<string, React.ReactElement> = {
    Dogs: <Dog className="w-20 h-20 mr-2" />,
    Cats: <Cat className="w-20 h-20 mr-2" />,
  };

  const [visibleSections, setVisibleSections] = useState<
    Record<string, boolean>
  >({});

  const toggleSection = (title: string) => {
    setVisibleSections((prev) => ({
      ...prev,
      [title]: !prev[title],
    }));
  };

  return (
    <section className="py-10 px-4 max-w-6xl mx-auto">
      <div className="flex flex-wrap gap-10 justify-center">
        {sections.map(({ title }) => (
          <button
            key={title}
            onClick={() => toggleSection(title)}
            className="position-absolute transform -translate-y-1/2 bg-white bg-opacity-80 backdrop-blur-md w-50 h-50 rounded-lg shadow-lg border-2 border-primary hover:bg-primary transition-colors duration-300 text-3xl font-semibold flex flex-col items-center justify-center cursor-pointer"
          >
            {sectionIcons[title]}
            {visibleSections[title] ? `Hide` : `${title}`}
          </button>
        ))}
      </div>

      {sections.map(({ title, data }) =>
        visibleSections[title] ? (
          <div
            key={title}
            className="grid gap-6 sm:grid-cols-2 md:grid-cols-3 mb-8"
          >
            {data.map((pet) => (
              <PetCard key={pet.id} pet={pet} />
            ))}
          </div>
        ) : null,
      )}
    </section>
  );
};
