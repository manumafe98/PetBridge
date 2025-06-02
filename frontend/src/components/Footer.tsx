const Footer = () => {
  return (
    <footer className="w-full bg-primary text-white py-6 absolute">
      <div className="max-w-6xl mx-auto px-4 align-bottom">
        <div className="flex justify-between items-center">
          <div className="flex gap-4 mt-2 md:mt-0 justify-center">
            <p className="text-sm hover:underline">NERCONF's Hackaton</p>
          </div>

          <p className="text-center">
            Made with ❤️ by
            <div className="flex gap-15 mt-2 md:mt-0 text-lg pt-3">
              <a
                target="_blank"
                rel="noopener noreferrer"
                href="https://github.com/manumafe98"
                className="hover:transform hover:scale-105 transition-transform duration-300 border-1 border-amber-50 p-2 rounded-3xl"
              >
                {" "}
                MANU
              </a>

              <a
                target="_blank"
                rel="noopener noreferrer"
                href="https://github.com/iru-codes"
                className="hover:transform hover:scale-105 transition-transform duration-300 border-1 border-amber-50 p-2 rounded-3xl"
              >
                {" "}
                IRU
              </a>
            </div>
          </p>

          <p className="text-sm">&copy; {new Date().getFullYear()} PetBridge</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
