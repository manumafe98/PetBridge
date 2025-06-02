import React, { useState } from "react";

type OptionType = "Adopt" | "Foster" | "Publisher";

const RoleSelector: React.FC = () => {
  const [selected, setSelected] = useState<OptionType>("Adopt");

  return (
    <div className="flex flex-col gap-2">
      <label className="text-sm text-center mt-5 font-medium text-gray-700">
        How do you want to help?:
      </label>
      <div className="flex gap-2 justify-center m-5">
        {(["Adopt", "Foster", "Publisher"] as OptionType[]).map((option) => (
          <label
            key={option}
            className={`cursor-pointer px-4 py-2 rounded-full border text-sm font-medium
                    ${
                      selected === option
                        ? "bg-primary text-white border-primary"
                        : "bg-white text-gray-700 border-gray-300 hover:bg-gray-100"
                    }`}
          >
            <input
              type="radio"
              name="userRole"
              value={option}
              checked={selected === option}
              onChange={() => setSelected(option)}
              className="hidden"
            />
            {option}
          </label>
        ))}
      </div>
    </div>
  );
};

export default RoleSelector;
