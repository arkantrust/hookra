import { Suspense } from "react";

import { ServerTime } from "@/components/server-time";
import { TimeDisplay, TimeDisplaySkeleton } from "@/components/time-display";

export default async function Home() {
  return (
    <div className="flex min-h-screen items-center justify-center font-sans">
      <main className="flex min-h-screen w-full max-w-3xl flex-col items-center justify-center px-16 py-32 sm:items-start">
        <h1 className="text-3xl font-bold">Hello, Cloudflare!</h1>
        <p className="mt-3 text-2xl">
          This is a Next.js app running on Cloudflare Workers using{" "}
          <a
            href="https://opennext.js.org/cloudflare"
            target="_blank"
            rel="noopener noreferrer"
            className="font-medium text-accent-foreground hover:underline"
          >
            OpenNext
          </a>
          .
        </p>
        <section className="mt-10 w-full max-w-2xl">
          <p className="text-xs tracking-[0.28em] text-muted-foreground uppercase">
            Streaming render comparison
          </p>
          <div className="mt-4 grid gap-6 border-y border-border/60 py-6 sm:grid-cols-[1fr_auto_1fr] sm:items-start">
            <div className="flex flex-col gap-2">
              <p className="text-sm font-medium text-foreground">Client render</p>
              <TimeDisplay label={"Local time"} className="text-base" />
            </div>

            <div className="hidden h-full w-px bg-border/60 sm:block" aria-hidden="true" />

            <div className="flex flex-col gap-2">
              <p className="text-sm font-medium text-foreground">Server render</p>
              <Suspense fallback={<TimeDisplaySkeleton />}>
                <ServerTime />
              </Suspense>
            </div>
          </div>
          <p className="mt-4 text-sm leading-relaxed text-muted-foreground">
            Local time updates in the browser, while server time is created at request time and
            streamed in when ready.
          </p>
        </section>
      </main>
    </div>
  );
}
