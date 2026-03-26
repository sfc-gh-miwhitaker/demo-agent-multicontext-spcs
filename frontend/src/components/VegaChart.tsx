import { useRef, useEffect, useState } from 'react';
import embed, { type VisualizationSpec } from 'vega-embed';

interface VegaChartProps {
  spec: object;
}

export function VegaChart({ spec }: VegaChartProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    let cancelled = false;

    embed(containerRef.current, spec as VisualizationSpec, {
      actions: false,
      renderer: 'svg',
      config: {
        autosize: { type: 'fit', contains: 'padding' },
        background: 'transparent',
        axis: {
          labelColor: '#94a3b8',
          titleColor: '#94a3b8',
          gridColor: '#334155',
          domainColor: '#475569',
          tickColor: '#475569',
        },
        legend: {
          labelColor: '#94a3b8',
          titleColor: '#94a3b8',
        },
        title: {
          color: '#e2e8f0',
        },
        view: {
          stroke: 'transparent',
        },
      },
    })
      .then((result) => {
        if (cancelled) result.view.finalize();
      })
      .catch((err) => {
        if (!cancelled) setError(err instanceof Error ? err.message : 'Failed to render chart');
      });

    return () => {
      cancelled = true;
    };
  }, [spec]);

  if (error) {
    return <div className="chart-error">Chart error: {error}</div>;
  }

  return <div ref={containerRef} className="vega-chart" />;
}
