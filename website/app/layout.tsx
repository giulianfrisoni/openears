import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = {
  title: 'OpenEars — Your earbuds, more at home on Mac',
  description: 'An open-source native macOS companion for earbuds. Starting with Nothing Ear (3), working toward AirPods-like convenience while preserving each device’s features.',
};
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
