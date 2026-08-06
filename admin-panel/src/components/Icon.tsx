// Line-style monochrome icons (stroke = currentColor), matching the app's SVG icon set.

interface IconProps {
  size?: number;
}

const base = (size: number) => ({
  width: size,
  height: size,
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 1.8,
  strokeLinecap: 'round' as const,
  strokeLinejoin: 'round' as const,
});

export const IconHome = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <path d="M3 10.5 12 3l9 7.5" />
    <path d="M5 9.5V21h14V9.5" />
    <path d="M10 21v-6h4v6" />
  </svg>
);

export const IconScale = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <path d="M12 3v18" />
    <path d="M8 21h8" />
    <path d="M4 7h16" />
    <path d="M6 7 3.5 13a2.8 2.8 0 0 0 5 0L6 7Z" />
    <path d="M18 7l-2.5 6a2.8 2.8 0 0 0 5 0L18 7Z" />
  </svg>
);

export const IconUsers = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <circle cx="9" cy="8" r="3.4" />
    <path d="M3.5 20c.6-3.4 2.8-5 5.5-5s4.9 1.6 5.5 5" />
    <path d="M16 5.4a3.4 3.4 0 0 1 0 5.9" />
    <path d="M17.6 15.3c1.7.7 2.7 2.2 3 4.7" />
  </svg>
);

export const IconCalendar = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <rect x="4" y="5" width="16" height="16" rx="3" />
    <path d="M8 3v4M16 3v4M4 10h16" />
  </svg>
);

export const IconBriefcase = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <rect x="3" y="7.5" width="18" height="13" rx="3" />
    <path d="M9 7.5V6a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v1.5" />
    <path d="M3 13h18" />
  </svg>
);

export const IconDollar = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <circle cx="12" cy="12" r="9" />
    <path d="M15 9.5c-.6-1-1.6-1.5-3-1.5-1.7 0-2.8.8-2.8 2s1 1.7 2.8 2c2 .3 3 1 3 2.3 0 1.4-1.3 2.2-3 2.2-1.5 0-2.6-.6-3.2-1.6" />
    <path d="M12 6.5v11" />
  </svg>
);

export const IconGraduation = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <path d="m12 4 10 4.5L12 13 2 8.5 12 4Z" />
    <path d="M6.5 10.8V16c0 1.4 2.5 2.8 5.5 2.8s5.5-1.4 5.5-2.8v-5.2" />
    <path d="M22 8.5V14" />
  </svg>
);

export const IconBuilding = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <rect x="5" y="3.5" width="14" height="17.5" rx="2" />
    <path d="M9 8h2M13 8h2M9 12h2M13 12h2M9 16h2M13 16h2" />
    <path d="M5 21h14" />
  </svg>
);

export const IconSettings = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <circle cx="12" cy="12" r="3.2" />
    <path d="M19 12a7 7 0 0 0-.14-1.4l2-1.55-2-3.46-2.36.95a7 7 0 0 0-2.42-1.4L13.7 2.6h-3.4l-.38 2.54a7 7 0 0 0-2.42 1.4l-2.36-.95-2 3.46 2 1.55A7 7 0 0 0 5 12c0 .48.05.94.14 1.4l-2 1.55 2 3.46 2.36-.95a7 7 0 0 0 2.42 1.4l.38 2.54h3.4l.38-2.54a7 7 0 0 0 2.42-1.4l2.36.95 2-3.46-2-1.55c.09-.46.14-.92.14-1.4Z" />
  </svg>
);

export const IconSearch = ({ size = 16 }: IconProps) => (
  <svg {...base(size)}>
    <circle cx="11" cy="11" r="7" />
    <path d="m20 20-3.5-3.5" />
  </svg>
);

export const IconBell = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <path d="M18 9a6 6 0 1 0-12 0c0 5-2 6-2 6h16s-2-1-2-6" />
    <path d="M10.3 19.5a2 2 0 0 0 3.4 0" />
  </svg>
);

export const IconCheck = ({ size = 14 }: IconProps) => (
  <svg {...base(size)}>
    <path d="m4.5 12.5 5 5 10-11" />
  </svg>
);

export const IconX = ({ size = 14 }: IconProps) => (
  <svg {...base(size)}>
    <path d="M6 6l12 12M18 6 6 18" />
  </svg>
);

export const IconTrendUp = ({ size = 16 }: IconProps) => (
  <svg {...base(size)}>
    <path d="m3 17 6-6 4 4 8-8" />
    <path d="M15 7h6v6" />
  </svg>
);

export const IconChevronRight = ({ size = 14 }: IconProps) => (
  <svg {...base(size)}>
    <path d="m9 5 7 7-7 7" />
  </svg>
);

export const IconLogout = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <path d="M14 4H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h7" />
    <path d="m17 8 4 4-4 4M21 12H10" />
  </svg>
);

export const IconShield = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <path d="M12 3 4.5 6v5.5c0 4.6 3.1 8 7.5 9.5 4.4-1.5 7.5-4.9 7.5-9.5V6L12 3Z" />
    <path d="m8.8 12 2.3 2.3 4.2-4.5" />
  </svg>
);

export const IconFile = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <path d="M13.5 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8.5L13.5 3Z" />
    <path d="M13.5 3v5.5H19" />
  </svg>
);

export const IconChat = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <path d="M21 11.5a8.5 8.5 0 0 1-8.5 8.5c-1.5 0-3-.4-4.3-1.1L3 20l1.1-5.2A8.5 8.5 0 1 1 21 11.5Z" />
    <path d="M8.5 10.5h7M8.5 13.5h4.5" />
  </svg>
);

export const IconBook = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v15.5H6.5A2.5 2.5 0 0 0 4 21V5.5Z" />
    <path d="M4 18.5A2.5 2.5 0 0 1 6.5 16H20" />
    <path d="M8.5 7.5h7" />
  </svg>
);

export const IconSparkle = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <path d="M11 4.5 12.6 9l4.4 1.6-4.4 1.6L11 16.5 9.4 12.2 5 10.6 9.4 9 11 4.5Z" />
    <path d="M18.5 15.5l.8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8.8-2.2Z" />
  </svg>
);

export const IconUserCheck = ({ size = 18 }: IconProps) => (
  <svg {...base(size)}>
    <circle cx="9" cy="8" r="3.4" />
    <path d="M3.5 20c.6-3.4 2.8-5 5.5-5 1.6 0 3 .5 4.1 1.5" />
    <path d="m15.5 18 2 2 4-4.5" />
  </svg>
);
