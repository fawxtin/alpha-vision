//+------------------------------------------------------------------+
//|                                                        LList.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict

/*
 *
 *
 * TODO: create an element list without pointers
 */
 
template<typename T>
class LElement {
   public:
      T *m_data;
      //T *m_previous = NULL;
      LElement<T> *m_next;
      
      LElement(T *data): m_data(data) { m_next = NULL; };
      void ~LElement() {
         if (CheckPointer(m_data) == POINTER_DYNAMIC) delete m_data;
      };
};

template<typename T>
class LList {
      
   public:
      LElement<T> *m_header;
      int m_counter;
      
      LList(): m_counter(0) { m_header = NULL; };
      
      void ~LList() {
         while (m_header != NULL) {
            LElement<T> *current = m_header;
            m_header = current.m_next;
            delete current;
         }
      }
      
      // add, get, delete
      int length() { return m_counter; }
      
      void add(T *element) {
         LElement<T> *content = new LElement<T>(element);
         if (m_header == NULL) {
            m_header = content;
         } else {
            LElement<T> *pointer = m_header;
            while (pointer.m_next != NULL)
               pointer = pointer.m_next;
            pointer.m_next = content;
         }
         m_counter++;
      }
      
      void drop(int index) {
         if (index < 0 || index >= m_counter) return;
         LElement<T> *pointer = m_header;
         LElement<T> *pointerFuture = m_header.m_next;
         if (index == 0) {
            m_header = pointerFuture;
            delete pointer;
         } else {
            for (int i = 0; i < index - 1; i++) {
               pointer = pointer.m_next;
            }
            pointerFuture = pointer.m_next;
            if (pointerFuture == NULL) return;
            pointer.m_next = pointerFuture.m_next;
            delete pointerFuture;
         }
         m_counter--;
      }
      
      T *operator[](int index) {
         if (index < 0 || index >= m_counter)
            return NULL;
      
         LElement<T> *pointer = m_header;
         for (int i = 0; i < index; i++) {
            pointer = pointer.m_next;
         }
         
         return pointer.m_data;
      }
};
