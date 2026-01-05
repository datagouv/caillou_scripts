(function(columnName) {
  // If no column name is provided, extract from all columns
  if (!columnName) {
    const cardNameElements = Array.from(document.querySelectorAll('[class*="Card_name__"]'));
    const titles = cardNameElements.map((el, index) => {
      return `${index + 1}. ${el.textContent.trim()}`;
    });
    console.log(`Found ${titles.length} card titles:\n`);
    console.log(titles.join('\n'));
    return titles;
  }
  
  // Find all list headers
  const listHeaders = Array.from(document.querySelectorAll('[class*="List_headerName__"]'));
  
  // Find the list that matches the column name
  const targetHeader = listHeaders.find(header => 
    header.textContent.trim().toLowerCase().includes(columnName.toLowerCase())
  );
  
  if (!targetHeader) {
    console.error(`Column "${columnName}" not found. Available columns:`);
    listHeaders.forEach(header => console.log(`  - ${header.textContent.trim()}`));
    return [];
  }
  
  // Navigate up to the list wrapper and find all cards within it
  const listWrapper = targetHeader.closest('[class*="List_innerWrapper__"]');
  const cardNameElements = Array.from(listWrapper.querySelectorAll('[class*="Card_name__"]'));
  
  // Extract text content from each card
  const titles = cardNameElements.map((el, index) => {
    return `${index + 1}. ${el.textContent.trim()}`;
  });
  
  // Display results
  console.log(`Found ${titles.length} card titles in column "${targetHeader.textContent.trim()}":\n`);
  console.log(titles.join('\n'));
  
  // Return the array for further use
  return titles;
})("À faire"); // Change the argument to the column name you want, or pass nothing for all columns