'use client';

import Hero from './components/hero';
import Services from './components/features';
import Footer from './components/footer';
import ChatWidget from './components/chat-widget';

export default function HomePage(): React.ReactElement {
  return (
    <>
      <Hero />
      <Services />
      <Footer />
      <ChatWidget />
    </>
  );
}
