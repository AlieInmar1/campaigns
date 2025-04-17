import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  Target,
  BarChart3,
  Database,
  Users,
  Settings
} from 'lucide-react';

interface NavItemProps {
  to: string;
  icon: React.ReactNode;
  children: React.ReactNode;
}

function NavItem({ to, icon, children }: NavItemProps) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        `flex items-center px-4 py-2 text-sm font-medium rounded-md ${
          isActive
            ? 'bg-primary-50 text-primary-700'
            : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
        }`
      }
    >
      {icon}
      <span className="ml-3">{children}</span>
    </NavLink>
  );
}

export function Sidebar() {
  return (
    <div className="w-64 flex-shrink-0 border-r border-gray-200 bg-white">
      <div className="h-full flex flex-col">
        <nav className="flex-1 px-2 py-4 space-y-1">
          <NavItem
            to="/"
            icon={<LayoutDashboard className="h-5 w-5" />}
          >
            Dashboard
          </NavItem>

          <NavItem
            to="/campaigns"
            icon={<Target className="h-5 w-5" />}
          >
            Campaigns
          </NavItem>

          <NavItem
            to="/campaigns/new"
            icon={<BarChart3 className="h-5 w-5" />}
          >
            Create Campaign
          </NavItem>

          <NavItem
            to="/audience-explorer"
            icon={<Users className="h-5 w-5" />}
          >
            Audience Explorer
          </NavItem>

          <NavItem
            to="/settings"
            icon={<Settings className="h-5 w-5" />}
          >
            Settings
          </NavItem>
        </nav>
      </div>
    </div>
  );
}
