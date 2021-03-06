//+------------------------------------------------------------------+
//|                                                     MenuItem.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include "..\Element.mqh"
#include "Button.mqh"
class CContextMenu;
//+------------------------------------------------------------------+
//| Class for creating a menu item                                   |
//+------------------------------------------------------------------+
class CMenuItem : public CButton
  {
private:
   //--- Pointer to the previous node
   CMenuItem        *m_prev_node;
   //--- Pointer to the attached context menu
   CContextMenu     *m_context_menu;
   //--- Menu item type
   ENUM_TYPE_MENU_ITEM m_type_menu_item;
   //--- Properties of the indication of the context menu
   bool              m_show_right_arrow;
   int               m_arrow_x_gap;
   //--- Checkbox state
   bool              m_checkbox_state;
   //--- State of the radio button and its identifier
   bool              m_radiobutton_state;
   int               m_radiobutton_id;
   //---
public:
                     CMenuItem(void);
                    ~CMenuItem(void);
   //--- Methods for creating a menu item
   bool              CreateMenuItem(const string text,const int x_gap,const int y_gap);
   //---
public:
   //    (1) Getting and (2) storing the pointer to the previous node
   void              GetPrevNodePointer(CMenuItem &object)                { m_prev_node=::GetPointer(object);    }
   CMenuItem        *GetPrevNodePointer(void)                       const { return(m_prev_node);                 }
   void              GetContextMenuPointer(CContextMenu &object)          { m_context_menu=::GetPointer(object); }
   CContextMenu     *GetContextMenuPointer(void)                    const { return(m_context_menu);              }
   //--- (1) Setting and getting the type, (2) index number
   void              TypeMenuItem(const ENUM_TYPE_MENU_ITEM type)         { m_type_menu_item=type;               }
   ENUM_TYPE_MENU_ITEM TypeMenuItem(void)                           const { return(m_type_menu_item);            }
   //--- (1) Display the sign of the presence of a context menu, (2) the general state of the checkbox item
   void              ShowRightArrow(const bool flag)                      { m_show_right_arrow=flag;             }
   bool              CheckBoxState(void)                            const { return(m_checkbox_state);            }
   void              CheckBoxState(const bool state);
   //--- (1) Identifier of the radio item, (2) state of the radio item
   void              RadioButtonID(const int id)                          { m_radiobutton_id=id;                 }
   int               RadioButtonID(void)                            const { return(m_radiobutton_id);            }
   bool              RadioButtonState(void)                         const { return(m_radiobutton_state);         }
   void              RadioButtonState(const bool state);
   //---
public:
   //--- Handler of chart events
   virtual void      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
   //--- Management
   virtual void      Show(void);
   virtual void      Hide(void);
   //--- Draws the control
   virtual void      Draw(void);
   //---
private:
   //--- Clicking on the menu item
   bool              OnClickMenuItem(const string pressed_object,const int id,const int index);
   //--- Draws the image
   virtual void      DrawImage(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMenuItem::CMenuItem(void) : m_type_menu_item(MI_SIMPLE),
                             m_checkbox_state(true),
                             m_radiobutton_id(0),
                             m_radiobutton_state(false),
                             m_show_right_arrow(true),
                             m_arrow_x_gap(18)
  {
//--- Save the name of the element class in the base class
   CElementBase::ClassName(CLASS_NAME);
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMenuItem::~CMenuItem(void)
  {
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CMenuItem::OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
//--- Handle the event in the base class
   CButton::OnEvent(id,lparam,dparam,sparam);
//--- Handling the event of left mouse button press on the control
   if(id==CHARTEVENT_CUSTOM+ON_CLICK_BUTTON)
     {
      if(OnClickMenuItem(sparam,(uint)lparam,(uint)dparam))
         return;
      //---
      return;
     }
  }
//+------------------------------------------------------------------+
//| Creates the menu item element                                    |
//+------------------------------------------------------------------+
#resource "\\Images\\EasyAndFastGUI\\Controls\\arrow_right_black.bmp"
#resource "\\Images\\EasyAndFastGUI\\Controls\\arrow_right_white.bmp"
#resource "\\Images\\EasyAndFastGUI\\Controls\\checkbox_mini_black.bmp"
#resource "\\Images\\EasyAndFastGUI\\Controls\\checkbox_mini_white.bmp"
//---
bool CMenuItem::CreateMenuItem(const string text,const int x_gap,const int y_gap)
  {
//--- Exit, if there is no pointer to the main control
   if(!CElement::CheckMainPointer())
      return(false);
//--- If there is no pointer to the previous node, the item is not a part of the context menu
   if(::CheckPointer(m_prev_node)==POINTER_INVALID)
     {
      //--- Exit, if the set type does not match
      if(m_type_menu_item!=MI_SIMPLE && m_type_menu_item!=MI_HAS_CONTEXT_MENU)
        {
         ::Print(__FUNCTION__," > The type of the independent menu item can be only MI_SIMPLE or MI_HAS_CONTEXT_MENU, ",
                 "that is only with a context menu.\n",
                 __FUNCTION__," > The menu item type can be set using the CMenuItem::TypeMenuItem()") method;
         return(false);
        }
     }
//--- Define the icons if the item contain a drop-down menu 
   if(m_type_menu_item==MI_HAS_CONTEXT_MENU)
     {
      CButton::TwoState(true);
      //--- If it is necessary to show an arrow as a sign of having a context menu
      if(m_show_right_arrow)
        {
         if(CButton::ImagesGroupTotal()<2)
           {
            CButton::AddImagesGroup(CElementBase::XSize()-m_arrow_x_gap,CElement::IconYGap());
            CButton::AddImage(1,"Images\\EasyAndFastGUI\\Controls\\arrow_right_black.bmp");
            CButton::AddImage(1,"Images\\EasyAndFastGUI\\Controls\\arrow_right_white.bmp");
           }
        }
     }
//--- If this is a checkbox
   if(m_type_menu_item==MI_CHECKBOX)
     {
      //--- The default images
      CButton::SetImage(0,0,"Images\\EasyAndFastGUI\\Controls\\checkbox_mini_black.bmp");
      CButton::SetImage(0,1,"Images\\EasyAndFastGUI\\Controls\\checkbox_mini_white.bmp");
      CButton::AddImage(0,"");
     }
//--- If this is a radio item     
   else if(m_type_menu_item==MI_RADIOBUTTON)
     {
      //--- The default images
      CButton::SetImage(0,0,"Images\\EasyAndFastGUI\\Controls\\checkbox_mini_black.bmp");
      CButton::SetImage(0,1,"Images\\EasyAndFastGUI\\Controls\\checkbox_mini_white.bmp");
      CButton::AddImage(0,"");
     }
//--- Properties
   CButton::NamePart("menu_item");
//--- Creating a control
   if(!CButton::CreateButton(text,x_gap,y_gap))
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Changing the state of the menu item of checkbox type             |
//+------------------------------------------------------------------+
void CMenuItem::CheckBoxState(const bool state)
  {
   m_checkbox_state=state;
   Update(true);
  }
//+------------------------------------------------------------------+
//| Changing the state of the menu item of radio item type           |
//+------------------------------------------------------------------+
void CMenuItem::RadioButtonState(const bool state)
  {
   m_radiobutton_state=state;
   Update(true);
  }
//+------------------------------------------------------------------+
//| Makes a menu item visible                                        |
//+------------------------------------------------------------------+
void CMenuItem::Show(void)
  {
//--- Exit, if this control is already visible
   if(CElementBase::IsVisible())
      return;
//--- Display the control
   CButton::Show();
//--- Update the position of objects
   Moving();
  }
//+------------------------------------------------------------------+
//| Hides a menu item                                                |
//+------------------------------------------------------------------+
void CMenuItem::Hide(void)
  {
//--- Exit if the element is hidden
   if(!CElementBase::IsVisible())
      return;
//--- Hide the element
   CButton::Hide();
//--- Zeroing variables
   CElementBase::IsVisible(false);
   CElementBase::MouseFocus(false);
  }
//+------------------------------------------------------------------+
//| Handling clicking on the menu item                               |
//+------------------------------------------------------------------+
bool CMenuItem::OnClickMenuItem(const string pressed_object,const int id,const int index)
  {
//--- Exit, if clicking was not on the button
   if(::StringFind(pressed_object,"menu_item")<0)
      return(false);
//--- Exit, if (1) the identifiers do not match or (2) the control is locked
   if(id!=CElementBase::Id() || index!=CElementBase::Index() || CElementBase::IsLocked())
      return(false);
//--- If this item does not contain a context menu
   if(m_type_menu_item==MI_HAS_CONTEXT_MENU)
     {
      if(::CheckPointer(m_context_menu)==POINTER_INVALID)
         return(true);
      //--- If the drop-down menu of this item has not been activated
      if(!m_context_menu.IsVisible())
        {
         //--- Show the context menu
         m_context_menu.Show();
         //--- Message to restore the available controls
         ::EventChartCustom(m_chart_id,ON_SET_AVAILABLE,CElementBase::Id(),0,"");
         //--- Send a message about the change in the graphical interface
         ::EventChartCustom(m_chart_id,ON_CHANGE_GUI,CElementBase::Id(),0.0,"");
        }
      else
        {
         int is_restore=1;
         if(CheckPointer(m_prev_node)!=POINTER_INVALID)
            is_restore=0;
         //--- Hide the context menu
         m_context_menu.Hide();
         //--- Send a signal for closing context menus, which are below this item
         ::EventChartCustom(m_chart_id,ON_HIDE_BACK_CONTEXTMENUS,CElementBase::Id(),0,"");
         //--- Message to restore the available controls
         ::EventChartCustom(m_chart_id,ON_SET_AVAILABLE,CElementBase::Id(),is_restore,"");
         //--- Send a message about the change in the graphical interface
         ::EventChartCustom(m_chart_id,ON_CHANGE_GUI,CElementBase::Id(),0.0,"");
        }
     }
//--- If this item does not contain a context menu, but is a part of a context menu itself
   else
     {
      //--- Message prefix with the program name
      string message=CElementBase::ProgramName();
      //--- If this is a checkbox, change its state
      if(m_type_menu_item==MI_CHECKBOX)
        {
         m_checkbox_state=(m_checkbox_state)? false : true;
         //--- Add to the message that this is a checkbox
         message+="_checkbox";
        }
      //--- If this is a radio item, change its state
      else if(m_type_menu_item==MI_RADIOBUTTON)
        {
         m_radiobutton_state=(m_radiobutton_state)? false : true;
         //--- Add to the message that this is a radio item
         message+="_radioitem_"+(string)m_radiobutton_id;
        }
      //--- Release the button
      CElementBase::MouseFocus(false);
      CElement::Update(true);
      //--- Send a message about it
      ::EventChartCustom(m_chart_id,ON_CLICK_MENU_ITEM,CElementBase::Id(),CElementBase::Index(),message);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Draws the control                                                |
//+------------------------------------------------------------------+
void CMenuItem::Draw(void)
  {
//--- Draw the background
   CButton::DrawBackground();
//--- Draw frame
   CButton::DrawBorder();
//--- Draw icon
   if(m_type_menu_item!=MI_SIMPLE)
      CMenuItem::DrawImage();
   else
      CButton::DrawImage();
//--- Draw text
   CElement::DrawText();
  }
//+------------------------------------------------------------------+
//| Draws the image                                                  |
//+------------------------------------------------------------------+
void CMenuItem::DrawImage(void)
  {
//--- Determine the index
   uint image_index=0;
//---
   if(m_type_menu_item==MI_CHECKBOX)
     {
      image_index=(m_checkbox_state)?(m_mouse_focus)? 1 : 0 : 2;
      //--- Save the index of the selected image
      CElement::ChangeImage(0,image_index);
     }
   else if(m_type_menu_item==MI_RADIOBUTTON)
     {
      image_index=(m_radiobutton_state)?(m_mouse_focus)? 1 : 0 : 2;
      //--- Save the index of the selected image
      CElement::ChangeImage(0,image_index);
     }
   else if(m_type_menu_item==MI_HAS_CONTEXT_MENU)
     {
      image_index=(m_mouse_focus || m_is_pressed)? 1 : 0;
      //--- Save the index of the selected image
      CElement::ChangeImage(0,0);
      CElement::ChangeImage(1,image_index);
     }
   else
     {
      //--- Save the index of the selected image
      CElement::ChangeImage(0,image_index);
     }
//--- Draw the image
   CElement::DrawImage();
  }
//+------------------------------------------------------------------+
