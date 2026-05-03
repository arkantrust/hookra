import { TimeDisplay } from "./time-display";

export async function ServerTime() {
  // Simulate a long-running server operation by delaying the promise resolution
  await new Promise((resolve) => setTimeout(() => resolve(null), 1500));
  const date = new Date();

  return <TimeDisplay label={"Server time"} initialDate={date} updatable={false} />;
}
