"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  Bot,
  PlayCircle,
  BarChart3,
  Activity,
  Cpu,
  Settings,
} from "lucide-react";

const navItems = [
  { href: "/",       label: "Dashboard",  icon: LayoutDashboard },
  { href: "/agents", label: "Agentes",    icon: Bot },
  { href: "/tasks",  label: "Ejecutar",   icon: PlayCircle },
  { href: "/stats",  label: "Estadísticas", icon: BarChart3 },
  { href: "/settings", label: "Configuración", icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-64 bg-gray-900 border-r border-gray-800 flex flex-col">
      {/* Logo */}
      <div className="p-6 border-b border-gray-800">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 bg-indigo-600 rounded-lg flex items-center justify-center">
            <Cpu className="w-5 h-5 text-white" />
          </div>
          <div>
            <p className="font-bold text-white text-sm">CEO-Agents</p>
            <p className="text-xs text-gray-400">Sistema Evolutivo</p>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 p-4 space-y-1">
        {navItems.map(({ href, label, icon: Icon }) => {
          const active = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                active
                  ? "bg-indigo-600 text-white"
                  : "text-gray-400 hover:text-white hover:bg-gray-800"
              }`}
            >
              <Icon className="w-4 h-4" />
              {label}
            </Link>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="p-4 border-t border-gray-800">
        <div className="flex items-center gap-2 text-xs text-gray-500">
          <Activity className="w-3 h-3 text-green-400" />
          <span>API: localhost:8080</span>
        </div>
        <p className="text-xs text-gray-600 mt-1">v2.0.0</p>
      </div>
    </aside>
  );
}
