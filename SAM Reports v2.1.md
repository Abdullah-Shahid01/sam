# **Product Requirements Document: SAM Reports (v2.1)**

## **1\. Overview**

The **Reports** feature provides SAM users with visual and actionable insights into their financial health. This version introduces comparative analytics, recurring transaction automation, and intelligent defaults to streamline the user experience from input to insight.

## **2\. Key Objectives**

* **Actionable Visualization:** Interactive tools that allow users to investigate spending via drill-downs and custom ranges.  
* **Smart Automation:** Minimize friction using a "Default Account" logic for voice inputs and automated recurring transaction scheduling.  
* **Scalable Performance:** Use snapshotting to ensure instant chart rendering.

## **3\. Feature Requirements**

### **3.1 Data & Categorization (The Foundation)**

* **Category Schema:** Support for category, is\_recurring, and frequency (Daily, Weekly, Monthly, Yearly).  
* **Account Management:**  
  * **Default Account:** Users can designate one account as "Default."  
  * **Voice Logic:** If a voice command like "Spent 20 dollars on lunch" lacks an account name, SAM automatically assigns it to the Default Account.  
* **Recurring vs. One-Time:**  
  * "Fixed Costs" are now officially **Recurring Costs**.  
  * Users can filter reports to see only recurring obligations to understand their "burn rate."

### **3.2 Advanced Visualizations**

* **A. Interactive Expense Breakdown (Donut Chart)**  
  * **Drill-down:** Tapping a slice navigates to a filtered list.  
  * **Filtering:** Toggle between "Recurring Only," "Discretionary Only," or "All."  
* **B. Income vs. Expense (Grouped Bar Chart)**  
  * **Comparison:** Ghost-bar overlay for previous period comparisons.  
* **C. Custom Date Selector:**  
  * Users can select pre-set ranges (Last 7 Days, This Month) or a **Custom Date Range** via a calendar picker to filter all charts and widgets.  
* **D. Net Worth Trend (Line Chart)**  
  * Scrubbing interaction for precise historical data.

### **3.3 Intelligence & Automation**

* **Recurring Transaction Engine:**  
  * When marking a transaction as recurring, the user selects a frequency.  
  * **Auto-Generation:** SAM automatically generates the next transaction instance based on the frequency (e.g., adding "Rent" on the 1st of every month).  
* **Heuristics Engine:** \* "Remember My Choice" logic for merchant-to-category mapping.  
* **Top Spenders & Anomaly Detection:**  
  * Highlight outliers and category spending spikes (\>20% vs average).

## **4\. User Experience (UX)**

### **4.1 Navigation & Theming**

* Dedicated 'Reports' tab.  
* Dynamic theme mapping for accessible chart colors (Light/Dark mode).

### **4.2 Validation & Error Handling**

To prevent data integrity issues, SAM will provide helpful prompts in the following scenarios:

* **Null/Zero Amount:** "Please enter an amount greater than 0."  
* **Missing Category:** "Help us track this better\! Please pick a category."  
* **Unclear Voice Input:** "I heard the amount, but couldn't catch the category. Is this \[Suggested Category\]?"

### **4.3 Empty States**

* Skeleton screens for loading and "Guided Entry" prompts for new users.

## **5\. Technical Specifications**

* **Library:** fl\_chart (Flutter).  
* **Storage Migrations:**  
  * accounts table: Add is\_default (boolean).  
  * transactions table: Add frequency (string/enum), parent\_id (for recurring series), and is\_recurring (boolean).  
* **Performance:**  
  * **Snapshotting:** MonthlyBalances table for $O(1)$ trend lookups.  
  * **Background Task:** A WorkManager (Android) or Background Fetch (iOS) task to process and insert scheduled recurring transactions.

## **6\. Implementation Roadmap**

| Phase | Focus | Deliverables |
| :---- | :---- | :---- |
| **Phase 1: MVP** | **Core & Validation** | Category schema, Default Account logic, Null-amount error prompts, Basic Charts. |
| **Phase 2: Action** | **Recurring & Ranges** | Recurring Cost Engine (Automation), Custom Date Range Selector, Drill-downs. |
| **Phase 3: Intel** | **Optimization** | Net Worth Snapshots, Anomaly detection, Heuristic auto-categorization. |

