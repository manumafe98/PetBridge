import Footer from "./components/Footer";
import Form from "./components/Form";
import Header from "./components/Header";
import Intro from "./components/Intro";
import PetSection from "./components/PetSection";
import "./index.css";

function App() {
  return (
    <body className="min-w-[570px]">
      <Header />
      <Intro />
      <PetSection />
      <Form />
      <Footer />
    </body>
  );
}

export default App;
