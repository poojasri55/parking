document.addEventListener('DOMContentLoaded', () => {
  const backToTopBtn = document.querySelector('.back-to-top');
  if (backToTopBtn) backToTopBtn.addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));

  const searchBtn = document.querySelector('.search-btn');
  const searchInput = document.querySelector('.search-input');
  if (searchBtn && searchInput) {
    const runSearch = () => {
      const query = searchInput.value.trim();
      if (!query) { alert('Please enter a parking zone, slot ID, or area to search.'); return; }
      alert('Parking search will be connected to the Parking Slot Module. Search: ' + query);
    };
    searchBtn.addEventListener('click', runSearch);
    searchInput.addEventListener('keydown', event => { if (event.key === 'Enter') { event.preventDefault(); runSearch(); } });
  }

  const account = document.querySelector('.nav-account');
  if (account) {
    account.setAttribute('role', 'link'); account.setAttribute('tabindex', '0');
    const goToLogin = () => { window.location.href = 'login.jsp'; };
    account.addEventListener('click', goToLogin);
    account.addEventListener('keydown', event => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); goToLogin(); } });
  }

  const myVehicles = document.querySelector('.nav-cart');
  if (myVehicles) {
    myVehicles.style.cursor = 'pointer';
    myVehicles.addEventListener('click', () => { window.location.href = 'vehicles'; });
  }

  const recentBookings = document.querySelector('.nav-returns');
  if (recentBookings) {
    recentBookings.style.cursor = 'pointer';
    recentBookings.addEventListener('click', () => { window.location.href = 'allocations'; });
  }
});
