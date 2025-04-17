import React from 'react';
import { Menu } from 'lucide-react';
import { Button } from '../ui/Button';

interface HeaderProps {
  toggleSidebar: () => void;
}

export function Header({ toggleSidebar }: HeaderProps) {
  return (
    <header className="bg-white shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex">
            <div className="flex-shrink-0 flex items-center">
              <Button
                variant="ghost"
                size="icon"
                onClick={toggleSidebar}
                className="mr-4"
              >
                <Menu className="h-6 w-6" />
              </Button>
              <span className="text-xl font-semibold text-gray-900">
                Marketing Reconciliation
              </span>
            </div>
          </div>
          
          <div className="flex items-center">
            {/* Add any header actions here */}
          </div>
        </div>
      </div>
    </header>
  );
}
