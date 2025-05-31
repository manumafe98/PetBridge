import { Menu } from "lucide-react";
import { useState } from "react";

const Header = () => {
  const [showExtraNav, setShowExtraNav] = useState(false);

  return (
    <header className="w-full border-b border-divider">
      <div className="hidden md:flex items-center justify-between px-8 py-4 bg-header">
        <div className="flex items-center  flex-row gap-4">
          <a href="/" className="flex items-center gap-2">
            <svg
              className="w-8 h-8 text-primary fill-current"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="currentColor"
            >
              <path
                d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 
                        0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z"
              />
              <path d="M0 0h24v24H0z" fill="none" />
            </svg>
            <span className="font-bold text-xl text-gray-800">Pet Bridge</span>
          </a>
        </div>

        <div className="flex items-center justify-center px-4 py-3 md:px-8 bg-white">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setShowExtraNav(!showExtraNav)}
              className="md:hidden"
            >
              <Menu className="w-6 h-6 text-primary" />
            </button>
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
              Shelters & Rescues
            </a>
            <a
              href="/resources"
              className="text-sm font-medium hover:text-primary"
            >
              Resources
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
                Shelters & Rescues
              </a>
              <a
                href="/resources"
                className="text-sm font-medium text-gray-700 hover:text-primary"
              >
                Resources
              </a>
            </nav>
          </div>
        )}

        <div className="flex items-center gap-4">
          <button className="hidden md:inline-flex px-4 py-2 gap-2 text-sm font-semibold text-white bg-primary rounded-full hover:bg-primary-dark transition cursor-pointer">
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

          <button className="inline-flex items-center justify-center w-10 h-10 text-gray-600 hover:text-primary md:hidden">
            <svg
              className="w-6 h-6"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 6h16M4 12h16M4 18h16"
              />
            </svg>
          </button>
        </div>
      </div>
      {/* 
            <nav className=" items-center gap-6 text-sm font-medium text-gray-700">
                <a href="#" className="hover:text-primary">Adopt</a>
                <a href="#" className="hover:text-primary">Foster</a>
                <a href="#" className="hover:text-primary">Get Involved</a>
                <a href="#" className="hover:text-primary">Shelters & Rescues</a>
                <a href="#" className="hover:text-primary">Pet Care</a>
            </nav> */}
    </header>
  );
};

export default Header;
