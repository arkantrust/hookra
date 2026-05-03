import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  reactCompiler: true,
  typescript: {
    // This disables the default Next.js type check during builds
    ignoreBuildErrors: true,
  },
  cacheComponents: true,
};

export default nextConfig;
