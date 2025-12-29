import { ArrowRight, Zap } from 'lucide-react';

interface HeroProps {
  onChatOpen?: () => void;
}

export default function Hero({ onChatOpen }: HeroProps): React.ReactElement {
  return (
    <section className="relative min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-900 via-purple-900 to-blue-900 overflow-hidden">
      {/* Animated Background Elements */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute w-96 h-96 bg-blue-500/30 rounded-full blur-3xl -top-48 -left-48 animate-pulse"></div>
        <div className="absolute w-96 h-96 bg-purple-500/30 rounded-full blur-3xl -bottom-48 -right-48 animate-pulse delay-1000"></div>
        <div className="absolute inset-0 bg-[url('/grid.svg')] opacity-10"></div>
      </div>

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-32 text-center">
        <div className="space-y-8">
          {/* Badge */}
          <div className="inline-flex items-center px-4 py-2 rounded-full bg-gradient-to-r from-blue-500/20 to-purple-500/20 backdrop-blur-sm border border-blue-400/30 text-blue-300 text-sm font-medium">
            <Zap className="w-4 h-4 mr-2 animate-pulse" />
            AI-Driven Acceleration
          </div>

          {/* Heading */}
          <h1 className="text-5xl sm:text-6xl lg:text-8xl font-bold tracking-tight text-white">
            Elevating Business to
            <span className="block bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400 bg-clip-text text-transparent">
              Move at Light Speed
            </span>
          </h1>

          {/* Tagline */}
          <p className="max-w-3xl mx-auto text-2xl font-semibold text-blue-300">
            Leapfrog the Competition with AI
          </p>

          {/* Description */}
          <p className="max-w-2xl mx-auto text-xl text-gray-300 leading-relaxed">
            Leapmove helps enterprises harness the power of modern technology and AI 
            to accelerate innovation, scale operations, and transform customer experiences.
          </p>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center pt-4">
            <button
              onClick={onChatOpen}
              className="group inline-flex items-center px-8 py-4 text-lg font-semibold text-white bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg hover:from-blue-700 hover:to-purple-700 transition-all duration-200 shadow-2xl hover:shadow-purple-500/50 hover:scale-105"
            >
              Start Your Journey
              <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </button>
            <button className="inline-flex items-center px-8 py-4 text-lg font-semibold text-white bg-white/10 backdrop-blur-sm border-2 border-white/30 rounded-lg hover:bg-white/20 transition-all duration-200">
              Explore Services
            </button>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-8 max-w-3xl mx-auto pt-16">
            <div className="text-center backdrop-blur-sm bg-white/5 rounded-2xl p-6 border border-white/10">
              <div className="text-4xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">10x</div>
              <div className="text-sm text-gray-300 mt-2">Faster Delivery</div>
            </div>
            <div className="text-center backdrop-blur-sm bg-white/5 rounded-2xl p-6 border border-white/10">
              <div className="text-4xl font-bold bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">AI-First</div>
              <div className="text-sm text-gray-300 mt-2">Architecture</div>
            </div>
            <div className="text-center backdrop-blur-sm bg-white/5 rounded-2xl p-6 border border-white/10">
              <div className="text-4xl font-bold bg-gradient-to-r from-pink-400 to-blue-400 bg-clip-text text-transparent">24/7</div>
              <div className="text-sm text-gray-300 mt-2">AI Support</div>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom Gradient Fade */}
      <div className="absolute inset-x-0 bottom-0 h-32 bg-gradient-to-t from-gray-900 to-transparent pointer-events-none"></div>
    </section>
  );
}
