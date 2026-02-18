# **Product Requirements Document: SAM Reports**

## **1\. Overview**

The **Reports** feature provides SAM users with visual and actionable insights into their financial health. Beyond simple tracking, this version introduces comparative analytics, drill-down capabilities, and intelligent categorization to help users change their financial behavior.

## **2\. Key Objectives**

* **Actionable Visualization:** Move from static charts to interactive tools that allow users to investigate spending.  
* **Scalable Performance:** Implement technical optimizations to ensure charts load instantly regardless of transaction volume.  
* **Smart Automation:** Leverage voice input and heuristics to reduce the manual burden of data entry.

## **3\. Feature Requirements**

### **3.1 Data & Categorization (The Foundation)**

* **Category Schema:** Every transaction must support a category field (e.g., Food, Housing, Transport, Subscriptions).  
* **Heuristics Engine:**  
  * **Auto-Categorization:** Map keywords from voice/manual input (e.g., "Starbucks" → Coffee).  
  * **Personalization:** If a user manually overrides a category, the system prompts: *"Should I always categorize \[Merchant\] as \[Category\]?"* and stores this preference.  
* **Fixed vs. Discretionary:** Allow categories to be flagged as "Fixed" (Rent, Utilities) or "Discretionary" (Dining out, Hobbies).

### **3.2 Advanced Visualizations**

* **A. Interactive Expense Breakdown (Donut Chart)**  
  * **Drill-down:** Tapping a slice navigates to a filtered transaction list for that specific category.  
  * **Filtering:** Toggle to exclude "Fixed Costs" to see only controllable spending.  
* **B. Income vs. Expense (Grouped Bar Chart)**  
  * **Comparison:** Show current period vs. previous period (ghost-bar overlay) to track month-over-month changes.  
  * **Haptics:** Provide subtle tactile feedback when switching between bar groups.  
* **C. Net Worth Trend (Line Chart)**  
  * **Interaction:** Implement a horizontal "scrubbing" gesture (long-press and slide) to see precise values at specific dates.  
  * **Data Source:** Uses the MonthlyBalances snapshot table for ![][image1] time-series retrieval.

### **3.3 Intelligence & Widgets**

* **Top Spenders Widget:** A "Hall of Shame" list below charts showing the top 3-5 largest transactions for the period to identify outliers.  
* **Anomaly Detection:** An "Insight Card" that appears if spending in a specific category exceeds the 3-month average by \>20%.  
* **Export Tool:** Generate a CSV or formatted PDF report for external accounting or tax purposes.

## **4\. User Experience (UX)**

* **Navigation:** Dedicated 'Reports' tab in the bottom nav bar.  
* **Theme Integration:** All chart colors must map to Theme.of(context).colorScheme to ensure accessibility in both Light and Dark modes.  
* **Empty States:** Use "Skeleton Screens" (ghost charts) instead of blank screens to guide new users to record their first transaction.

## **5\. Technical Specifications**

* **Library:** fl\_chart (Flutter).  
* **Performance Optimization:** \* **Snapshotting:** Create a MonthlyBalances table updated via database triggers or at month-end.  
  * **Calculation Offloading:** Perform complex aggregations (e.g., Net Worth replaying) in a background isolate to prevent UI jank.  
* **Storage:** Schema migration to include is\_fixed (boolean) and merchant\_handle (string) for categorization heuristics.

## **6\. Implementation Roadmap**

| Phase | Focus | Deliverables |
| :---- | :---- | :---- |
| **Phase 1: MVP** | **Core Visualization** | Category field, Basic Donut/Bar charts, Manual category selection, Theme integration. |
| **Phase 2: Action** | **Navigation & Tools** | Drill-down navigation, Fixed/Discretionary toggle, CSV Export, "Top Spenders" widget. |
| **Phase 3: Intelligence** | **Automation** | Net Worth (Snapshots), Heuristic "Remember My Choice" logic, Anomaly detection cards. |

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACgAAAAYCAYAAACIhL/AAAACVUlEQVR4Xu2WvWtUQRTFXxAhQUGQbB7Zj/f2409YEhDEysYi1uktkt7CVrATi0A68S8IacTCxiKkSmkTAkYhiFVErZJCSOK5u3f2zZw3+/YuJJgiP7hk37l3Zs6deTubJLl2zLAQQWsspQPMhTdMJs/zn41Go8n6ONJ04Q7GnLE+EQz6irhA/EAc6+cDrvNpt9tfEu/A+eSRnyVphNlkmqbSkZjZ9PVms3lf9Te+7oD+vGoRmHsv41l3IHeI+MD6EG210+ksyyTyNywYApNzksdiLzkneq1Wu8t6lmXfkXuNOKkyKFTme73egi6+wTkf3cVzX0NDaZ7lv3yNyWwG99DQY9YH6MKVEwixOjzvI574GpMbDMJcFzWnhVIcbaoLnxTJOGMMXtTr9XlfYywGwUy0BuKRJNDBQ875iAk2KO9ddFLCaHDQrOxkSZSougYEDHyhtTtOw+dF08KZ3WCr1VoqiYbBg+3XutEVN84g34G57iDrjNRgI1aCCSwGkX8lNdjlddKjBhlnkHUGOy0Gw28yBu7J4Ng9prjd+8MJd7GzzpgNDtdZDER3ByLeBQkF+l9ZgHVH2FxxNnRKZoNJ+Q1JEryYTyUpP0l4vCVfGDx/FA3X0COu90HNDurXWBe08VLETku+HMgdsR6Ags86yW/EM9HK7YSg7gFin/VpwRzbaHTVPU9a11IxQpvqsG7F/c6zfmmg810scBj0ZGjQlWDsFuJbkLwcChdY4G23273nJU30+/3bGPuJ9StBjymydxFJySv+j9Rh4wdX5/4b05qatt7OP020u3rfhQJ6AAAAAElFTkSuQmCC>