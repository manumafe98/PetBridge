import React from "react";
import type { Pet } from "../types/Pet";

interface PetCardProps {
  pet: Pet;
}

export const PetCard: React.FC<PetCardProps> = ({ pet }) => {
  return (
    <div className="bg-white rounded-lg shadow-md mt-10 p-4 border-2 border-divider transition-transform duration-300 hover:scale-105 hover:shadow-lg">
      <img
        src={pet.image}
        alt={pet.name}
        className="w-full h-55 object-contain rounded-3xl"
      />
      <h2 className="text-xl font-semibold mt-2">{pet.name}</h2>
      <p className="text-gray-600">{pet.description}</p>
      <p className="text-gray-500 text-sm mt-1">Location: {pet.location}</p>
    </div>
  );
};
