"use client";

import { useEffect, useState } from "react";

import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";

export function TimeDisplay({
  label,
  initialDate = new Date(),
  updatable = true,
  className,
}: {
  label?: string;
  initialDate?: Date;
  updatable?: boolean;
  className?: string;
}) {
  const [date, setDate] = useState(initialDate);

  useEffect(() => {
    if (!updatable) {
      return;
    }

    const interval = setInterval(() => {
      setDate(new Date());
    }, 1000);

    return () => clearInterval(interval);
  }, [updatable]);

  const { iso, display } = {
    iso: date.toISOString(),
    display: new Intl.DateTimeFormat("en-US", {
      dateStyle: "medium",
      timeStyle: "long",
    }).format(date),
  };

  return (
    <p className={cn(`text-base text-muted-foreground`, className)}>
      {label ?? "Local time"}:{" "}
      <time dateTime={iso} className="font-medium text-foreground">
        {display}
      </time>
    </p>
  );
}

export function TimeDisplaySkeleton({ className }: { className?: string }) {
  return (
    <div className={cn(`text-base text-muted-foreground`, className)}>
      <Skeleton className="mr-2 ml-0 inline-block h-5 w-22 align-middle" />
      <Skeleton className="inline-block h-5 w-63 align-middle" />
    </div>
  );
}
