import { Github, Twitter, Linkedin } from 'lucide-react';

interface FooterLink {
  title: string;
  href: string;
}

interface FooterSection {
  title: string;
  links: FooterLink[];
}

const footerSections: FooterSection[] = [
  {
    title: 'Services',
    links: [
      { title: 'AI Engineering Uplift', href: '#ai-training' },
      { title: 'Enterprise Solutions', href: '#enterprise' },
      { title: 'AI Agent Integration', href: '#ai-agents' },
      { title: 'Consulting', href: '#consulting' },
    ],
  },
  {
    title: 'Company',
    links: [
      { title: 'About Leapmove', href: '#about' },
      { title: 'Case Studies', href: '#case-studies' },
      { title: 'Careers', href: '#careers' },
      { title: 'Contact', href: '#contact' },
    ],
  },
  {
    title: 'Resources',
    links: [
      { title: 'Blog', href: '#blog' },
      { title: 'Documentation', href: '#docs' },
      { title: 'AI Newsletter', href: '#newsletter' },
      { title: 'Support', href: '#support' },
    ],
  },
  {
    title: 'Legal',
    links: [
      { title: 'Privacy Policy', href: '#privacy' },
      { title: 'Terms of Service', href: '#terms' },
      { title: 'Security', href: '#security' },
      { title: 'Compliance', href: '#compliance' },
    ],
  },
];

export default function Footer(): React.ReactElement {
  const currentYear: number = new Date().getFullYear();

  return (
    <footer className="bg-gray-50 dark:bg-gray-900 border-t border-gray-200 dark:border-gray-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {/* Main Footer Content */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-8">
          {footerSections.map((section: FooterSection) => (
            <div key={section.title}>
              <h3 className="text-sm font-semibold text-gray-900 dark:text-white uppercase tracking-wider mb-4">
                {section.title}
              </h3>
              <ul className="space-y-3">
                {section.links.map((link: FooterLink) => (
                  <li key={link.title}>
                    <a
                      href={link.href}
                      className="text-gray-600 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                    >
                      {link.title}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Bottom Bar */}
        <div className="pt-8 border-t border-gray-200 dark:border-gray-800">
          <div className="flex flex-col md:flex-row justify-between items-center space-y-4 md:space-y-0">
            {/* Copyright */}
            <div className="text-gray-600 dark:text-gray-400 text-sm">
              © {currentYear} Leapmove. Elevating business with AI. All rights reserved.
            </div>

            {/* Social Links */}
            <div className="flex space-x-6">
              <a
                href="https://github.com"
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-600 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                aria-label="GitHub"
              >
                <Github className="w-5 h-5" />
              </a>
              <a
                href="https://twitter.com"
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-600 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                aria-label="Twitter"
              >
                <Twitter className="w-5 h-5" />
              </a>
              <a
                href="https://linkedin.com"
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-600 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                aria-label="LinkedIn"
              >
                <Linkedin className="w-5 h-5" />
              </a>
            </div>
          </div>

          {/* Deployment Info */}
          <div className="mt-4 text-center text-xs text-gray-500 dark:text-gray-500">
            Enterprise-grade infrastructure • AI-powered solutions • Built with Next.js 15
          </div>
        </div>
      </div>
    </footer>
  );
}
