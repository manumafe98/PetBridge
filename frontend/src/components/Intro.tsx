import banner from "../assets/img/banner.png";

const Intro = () => {
  return (
    <div className="relative w-full h-96 flex items-center justify-center text-center border-b-8 border-primary">
      <img
        src={banner}
        alt="Banner"
        className="absolute inset-0 w-full h-full object-cover object-top opacity-80"
      />

      <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-gray-800/40 to-transparent"></div>

      <div className="relative z-10 flex flex-col items-center justify-center gap-4 px-4">
        <h1 className="text-3xl md:text-5xl font-bold text-white drop-shadow-lg">
          Find your soul pet companion
        </h1>
        <p className="text-lg md:text-xl text-white drop-shadow">
          Adopt a pet with transparency and security. They are counting on you!
        </p>
      </div>
    </div>
  );
};

export default Intro;
