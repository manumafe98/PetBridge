import RoleSelector from "./RoleSelector";

const Form = () => {
  return (
    <form className="m-10 md:w-[35%] md:mx-auto border-2 border-primary rounded-2xl p-5">
      <h2 className="text-4xl text-center font-bold m-4">Want to help?</h2>
      <div className="mb-4">
        <label
          htmlFor="name"
          className="block text-sm font-medium text-gray-700"
        >
          Name
        </label>
        <input
          type="text"
          id="name"
          name="name"
          className="mt-1 block w-full border-gray-300 shadow-sm focus:ring-blue-500 focus:border-blue-500 border-1 border-primary rounded-2xl"
          required
        />
      </div>

      <RoleSelector />

      <div className="px-4 py-6 bg-white">
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Upload avatar:
        </label>
        <label className="cursor-pointer inline-block file-upload-wrapper">
          <span className="block w-full text-sm text-white bg-primary hover:bg-primary-dark font-semibold py-2 px-4 text-center rounded-full">
            Select File
          </span>
          <input
            type="file"
            accept="image/png, image/jpeg"
            className="hidden"
          />
        </label>
      </div>

      <div className="justify-center flex items-center">
        <button
          type="submit"
          className="w-40 px-4 py-2 bg-primary text-white rounded-md focus:outline-none hover:bg-primary-dark focus:ring-2 focus:ring-offset-2"
        >
          Submit
        </button>
      </div>
    </form>
  );
};

export default Form;
