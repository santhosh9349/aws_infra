import { GraduationCap, Rocket, Bot } from 'lucide-react';

interface Service {
  icon: React.ReactElement;
  title: string;
  description: string;
  features: string[];
}

const services: Service[] = [
  {
    icon: <GraduationCap className="w-8 h-8" />,
    title: 'AI Engineering Uplift',
    description: 'Empower your in-house teams with cutting-edge AI knowledge and hands-on training.',
    features: [
      'Custom AI/ML workshops tailored to your industry',
      'LLM integration and prompt engineering masterclasses',
      'Hands-on labs with OpenAI, Claude, and Gemini',
      'AI architecture and best practices',
      'RAG systems and vector database training',
      'Ongoing mentorship and support',
    ],
  },
  {
    icon: <Rocket className="w-8 h-8" />,
    title: 'Scalable Enterprise & E-commerce',
    description: 'High-performance, AI-enhanced platforms that grow with your business.',
    features: [
      'Next.js 15 and React 19 enterprise applications',
      'AWS infrastructure with EC2, ALB, and CloudFront',
      'Terraform IaC for reproducible deployments',
      'Real-time analytics and AI-powered insights',
      'Headless CMS and e-commerce solutions',
      'Sub-50ms response times at scale',
    ],
  },
  {
    icon: <Bot className="w-8 h-8" />,
    title: 'AI Agent Integration',
    description: 'Intelligent chatbots and AI agents that handle first-line customer support 24/7.',
    features: [
      'Custom-trained AI agents on your business data',
      'Multi-channel deployment (web, Slack, WhatsApp)',
      'Seamless handoff to human agents',
      'Real-time sentiment analysis',
      'Automated ticket creation and routing',
      'Enterprise security and compliance',
    ],
  },
];

export default function Services(): React.ReactElement {
  return (
    <section className="py-24 bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl font-bold text-white mb-4">
            Our Services
          </h2>
          <p className="text-xl text-gray-400">
            End-to-end solutions to accelerate your AI transformation
          </p>
        </div>

        {/* Services Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {services.map((service: Service, index: number) => (
            <div
              key={index}
              className="group relative p-8 rounded-2xl bg-gradient-to-br from-gray-800 to-gray-900 border border-gray-700 hover:border-purple-500 transition-all duration-300 hover:shadow-2xl hover:shadow-purple-500/20"
            >
              {/* Glow Effect */}
              <div className="absolute inset-0 bg-gradient-to-br from-blue-500/0 to-purple-500/0 group-hover:from-blue-500/10 group-hover:to-purple-500/10 rounded-2xl transition-all duration-300"></div>
              
              <div className="relative z-10">
                {/* Icon */}
                <div className="w-16 h-16 rounded-xl bg-gradient-to-br from-blue-500 to-purple-600 text-white flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                  {service.icon}
                </div>

                {/* Title */}
                <h3 className="text-2xl font-bold text-white mb-4">
                  {service.title}
                </h3>

                {/* Description */}
                <p className="text-gray-400 leading-relaxed mb-6">
                  {service.description}
                </p>

                {/* Features List */}
                <ul className="space-y-3">
                  {service.features.map((feature: string, idx: number) => (
                    <li key={idx} className="flex items-start text-sm text-gray-300">
                      <svg
                        className="w-5 h-5 text-purple-400 mr-2 flex-shrink-0 mt-0.5"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M5 13l4 4L19 7"
                        />
                      </svg>
                      {feature}
                    </li>
                  ))}
                </ul>

                {/* CTA */}
                <button className="mt-8 w-full py-3 px-4 rounded-lg bg-white/5 hover:bg-white/10 border border-white/10 hover:border-purple-500 text-white font-semibold transition-all duration-200">
                  Learn More
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* Bottom CTA */}
        <div className="mt-20 text-center">
          <p className="text-gray-400 mb-6">
            Ready to transform your business with AI?
          </p>
          <button className="inline-flex items-center px-8 py-4 text-lg font-semibold text-white bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg hover:from-blue-700 hover:to-purple-700 transition-all duration-200 shadow-xl hover:shadow-purple-500/50">
            Schedule a Consultation
          </button>
        </div>
      </div>
    </section>
  );
}
