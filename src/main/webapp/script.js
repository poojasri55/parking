document.addEventListener('DOMContentLoaded', () => {
  // Back to top button with smooth scroll & keyboard support
  const backToTopBtn = document.querySelector('.back-to-top');
  if (backToTopBtn) {
    const scrollToTop = () => window.scrollTo({ top: 0, behavior: 'smooth' });
    backToTopBtn.addEventListener('click', scrollToTop);
    backToTopBtn.addEventListener('keydown', (event) => {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        scrollToTop();
      }
    });
  }

  // Global Keyboard Shortcut: Ctrl+K or Cmd+K to focus search input
  const desktopSearchInput = document.querySelector('.omnibar-search .search-input');
  window.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      if (desktopSearchInput) {
        desktopSearchInput.focus();
        desktopSearchInput.select();
      }
    }
  });

  // Universal Search Handler
  const setupSearch = (inputSelector, btnSelector) => {
    const input = document.querySelector(inputSelector);
    const btn = document.querySelector(btnSelector);
    if (!input || !btn) return;

    const performSearch = () => {
      const query = input.value.trim().toLowerCase();
      if (!query) {
        alert('Please enter a parking zone, slot ID (e.g. A-101), or floor to search.');
        input.focus();
        return;
      }
      
      if (query.includes('book') || query.includes('reserve') || query.includes('alloc')) {
        window.location.href = 'allocations';
      } else if (query.includes('vehic') || query.includes('car') || query.includes('bike')) {
        window.location.href = 'vehicles';
      } else if (query.includes('monitor') || query.includes('gate') || query.includes('entry') || query.includes('exit')) {
        window.location.href = 'monitoring';
      } else if (query.includes('admin')) {
        window.location.href = 'admin';
      } else {
        // Default to slot availability search
        window.location.href = 'parking-slots';
      }
    };

    btn.addEventListener('click', performSearch);
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        performSearch();
      }
    });
  };

  setupSearch('.omnibar-search .search-input', '.omnibar-search .search-submit-btn');
  setupSearch('.mobile-search-input', '.mobile-search-btn');

  // Mobile Navigation Drawer Toggle
  const mobileToggle = document.getElementById('mobileNavToggle');
  const mobileDrawer = document.getElementById('mobileNavDrawer');
  if (mobileToggle && mobileDrawer) {
    mobileToggle.addEventListener('click', () => {
      mobileDrawer.classList.toggle('open');
      const icon = mobileToggle.querySelector('i');
      if (icon) {
        if (mobileDrawer.classList.contains('open')) {
          icon.classList.remove('fa-bars');
          icon.classList.add('fa-xmark');
        } else {
          icon.classList.remove('fa-xmark');
          icon.classList.add('fa-bars');
        }
      }
    });
  }

  // User Profile Pill in Navbar
  const userProfile = document.querySelector('.nav-user-profile');
  if (userProfile) {
    userProfile.setAttribute('role', 'link');
    userProfile.setAttribute('tabindex', '0');
    const goToAuth = () => { window.location.href = 'login.jsp'; };
    userProfile.addEventListener('click', goToAuth);
    userProfile.addEventListener('keydown', (event) => {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        goToAuth();
      }
    });
  }

  // Campus Facility Selector interaction
  const facilityChip = document.querySelector('.facility-chip');
  if (facilityChip) {
    facilityChip.addEventListener('click', () => {
      window.location.href = 'parking-slots';
    });
  }

  // Smooth scroll for in-page anchor links
  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener('click', function (e) {
      const targetId = this.getAttribute('href');
      if (targetId && targetId !== '#') {
        const targetElement = document.querySelector(targetId);
        if (targetElement) {
          e.preventDefault();
          targetElement.scrollIntoView({ behavior: 'smooth' });
        }
      }
    });
  });
});
