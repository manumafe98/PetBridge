import { Menu } from "lucide-react";
import { useState } from "react";

const Header = () => {
  const [showExtraNav, setShowExtraNav] = useState(false);

  return (
    <header className="w-full border-b border-divider">
      <div className="flex items-center justify-between px-4 py-4 bg-header md:px-8">
        <div className="flex items-center gap-4">
          <a href="/" className="flex items-center gap-2">
            <img
              src="/PetBridge_horizontal.png"
              alt="PetBridge"
              className="w-30 md:w-20"
            />
            <span className="font-bold text-xl text-gray-800">Pet Bridge</span>
          </a>
        </div>

        <div className="flex items-center gap-4 md:flex-row-reverse">
          <div className="flex items-center gap-4">
            <button className="flex px-4 py-2 gap-2 text-sm font-semibold text-white bg-primary rounded-full hover:bg-primary-dark transition cursor-pointer">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                className="lucide lucide-wallet-icon lucide-wallet"
              >
                <path d="M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1" />
                <path d="M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4" />
              </svg>
              Connect
            </button>
          </div>

          <div className="flex items-center justify-end md:justify-center px-4 py-3 md:px-8 bg-white">
            <div className="flex items-center gap-4">
              <button
                onClick={() => setShowExtraNav(!showExtraNav)}
                className="md:hidden"
              >
                <Menu className="w-6 h-6 text-primary" />
              </button>
            </div>
          </div>

          <div className="hidden md:flex items-center gap-6">
            <a href="/dogs" className="text-sm font-medium hover:text-primary">
              Dogs
            </a>
            <a href="/cats" className="text-sm font-medium hover:text-primary">
              Cats
            </a>
            <a
              href="/shelters"
              className="text-sm font-medium hover:text-primary"
            >
              Adopt
            </a>
            <a
              href="/resources"
              className="text-sm font-medium hover:text-primary"
            >
              Foster
            </a>
          </div>
        </div>

        {showExtraNav && (
          <div className="md:hidden bg-header-extra border-t border-divider">
            <nav className="flex flex-col p-4 gap-3">
              <a
                href="/dogs"
                className="text-sm font-medium text-gray-700 hover:text-primary"
              >
                Dogs
              </a>
              <a
                href="/cats"
                className="text-sm font-medium text-gray-700 hover:text-primary"
              >
                Cats
              </a>
              <a
                href="/shelters"
                className="text-sm font-medium text-gray-700 hover:text-primary"
              >
                Adopt
              </a>
              <a
                href="/resources"
                className="text-sm font-medium text-gray-700 hover:text-primary"
              >
                Foster
              </a>
            </nav>
          </div>
        )}
      </div>
    </header>
  );
};

export default Header;
