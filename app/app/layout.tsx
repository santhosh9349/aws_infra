import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Leapmove - Elevating Business with AI',
  description: 'AI-driven acceleration for enterprises. Training, scalable solutions, and AI agent integration to help you leapfrog the competition.',
};

interface RootLayoutProps {
  children: React.ReactNode;
}

export default function RootLayout({ children }: RootLayoutProps): React.ReactElement {
  return (
    <html lang="en">
      <body className="antialiased">
        {children}
      </body>
    </html>
  );
}
