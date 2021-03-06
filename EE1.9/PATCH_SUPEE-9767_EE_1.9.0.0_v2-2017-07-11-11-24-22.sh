#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


PATCH_SUPEE-9767_EE_1.9.0.0_v2 | EE_1.9.0.0 | v2 | 6566db274beaeb9bcdb56a62e02cc2da532e618c | Thu Jun 22 04:30:03 2017 +0300 | v1.14.3.3..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/PageCache/Helper/Form/Key.php app/code/core/Enterprise/PageCache/Helper/Form/Key.php
index 58983d6..facc6a3 100644
--- app/code/core/Enterprise/PageCache/Helper/Form/Key.php
+++ app/code/core/Enterprise/PageCache/Helper/Form/Key.php
@@ -76,4 +76,45 @@ class Enterprise_PageCache_Helper_Form_Key extends Mage_Core_Helper_Abstract
         $content = str_replace(self::_getFormKeyMarker(), $formKey, $content, $replacementCount);
         return ($replacementCount > 0);
     }
+
+    /**
+     * Get form key cache id
+     *
+     * @param boolean $renew
+     * @return string
+     */
+    public static function getFormKeyCacheId($renew = false)
+    {
+        $formKeyId = Enterprise_PageCache_Model_Cookie::getFormKeyCookieValue();
+        if ($renew && $formKeyId) {
+            Mage::app()->getCache()->clean(Zend_Cache::CLEANING_MODE_MATCHING_ANY_TAG, array(self::getFormKeyCacheId()));
+            $formKeyId = false;
+            Mage::unregister('cached_form_key_id');
+        }
+        if (!$formKeyId) {
+            if (!$formKeyId = Mage::registry('cached_form_key_id')) {
+                $formKeyId = Enterprise_PageCache_Helper_Data::getRandomString(16);
+                Enterprise_PageCache_Model_Cookie::setFormKeyCookieValue($formKeyId);
+                Mage::register('cached_form_key_id', $formKeyId);
+            }
+        }
+        return $formKeyId;
+    }
+
+    /**
+     * Get cached form key
+     *
+     * @param boolean $renew
+     * @return string
+     */
+    public static function getFormKey($renew = false)
+    {
+        $formKeyId = self::getFormKeyCacheId($renew);
+        $formKey = Mage::app()->loadCache($formKeyId);
+        if ($renew) {
+            $formKey = Enterprise_PageCache_Helper_Data::getRandomString(16);
+            Mage::app()->saveCache($formKey, $formKeyId, array(Enterprise_PageCache_Model_Processor::CACHE_TAG));
+        }
+        return $formKey;
+    }
 }
diff --git app/code/core/Enterprise/PageCache/Model/Observer.php app/code/core/Enterprise/PageCache/Model/Observer.php
index 878e4ba..11b6d01 100644
--- app/code/core/Enterprise/PageCache/Model/Observer.php
+++ app/code/core/Enterprise/PageCache/Model/Observer.php
@@ -314,7 +314,7 @@ class Enterprise_PageCache_Model_Observer
         $this->_getCookie()->set(Enterprise_PageCache_Model_Cookie::COOKIE_RECENTLY_COMPARED,
             implode(',', $recentlyComparedProducts));
 
-       return $this;
+        return $this;
     }
 
     /**
@@ -366,6 +366,8 @@ class Enterprise_PageCache_Model_Observer
         $productIds = implode(',', $productIds);
         Enterprise_PageCache_Model_Cookie::registerViewedProducts($productIds, $countLimit, false);
 
+        $this->updateFormKeyCookie();
+
         return $this;
 
     }
@@ -381,6 +383,7 @@ class Enterprise_PageCache_Model_Observer
             return $this;
         }
         $this->_getCookie()->updateCustomerCookies();
+        $this->updateFormKeyCookie();
         return $this;
     }
 
@@ -407,6 +410,7 @@ class Enterprise_PageCache_Model_Observer
         $this->_getCookie()->setObscure(Enterprise_PageCache_Model_Cookie::COOKIE_WISHLIST_ITEMS,
             'wishlist_item_count_' . Mage::helper('wishlist')->getItemCount());
 
+        $this->updateFormKeyCookie();
         return $this;
     }
 
@@ -488,11 +492,17 @@ class Enterprise_PageCache_Model_Observer
             return;
         }
 
-        /** @var $session Mage_Core_Model_Session  */
-        $session = Mage::getSingleton('core/session');
-        $cachedFrontFormKey = Enterprise_PageCache_Model_Cookie::getFormKeyCookieValue();
+        $cachedFrontFormKey = Enterprise_PageCache_Helper_Form_Key::getFormKey();
         if ($cachedFrontFormKey) {
-            $session->setData('_form_key', $cachedFrontFormKey);
+            Mage::getSingleton('core/session')->setData('_form_key', $cachedFrontFormKey);
         }
     }
+
+    /**
+     * Updates FPC form key
+     */
+    public function updateFormKeyCookie()
+    {
+        Enterprise_PageCache_Helper_Form_Key::getFormKey(true);
+    }
 }
diff --git app/code/core/Enterprise/PageCache/Model/Processor.php app/code/core/Enterprise/PageCache/Model/Processor.php
index 3a30e551..3488216 100644
--- app/code/core/Enterprise/PageCache/Model/Processor.php
+++ app/code/core/Enterprise/PageCache/Model/Processor.php
@@ -265,11 +265,9 @@ class Enterprise_PageCache_Model_Processor
             $isProcessed = false;
         }
 
-        if (isset($_COOKIE[Enterprise_PageCache_Model_Cookie::COOKIE_FORM_KEY])) {
-            $formKey = $_COOKIE[Enterprise_PageCache_Model_Cookie::COOKIE_FORM_KEY];
-        } else {
-            $formKey = Enterprise_PageCache_Helper_Data::getRandomString(16);
-            Enterprise_PageCache_Model_Cookie::setFormKeyCookieValue($formKey);
+        $formKey = Enterprise_PageCache_Helper_Form_Key::getFormKey();
+        if (!$formKey) {
+            $formKey = Enterprise_PageCache_Helper_Form_Key::getFormKey(true);
         }
 
         Enterprise_PageCache_Helper_Form_Key::restoreFormKey($content, $formKey);
diff --git app/code/core/Mage/Admin/Model/Session.php app/code/core/Mage/Admin/Model/Session.php
index 1e15dc6..ec4649f 100644
--- app/code/core/Mage/Admin/Model/Session.php
+++ app/code/core/Mage/Admin/Model/Session.php
@@ -117,6 +117,7 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
             $user = $this->_factory->getModel('admin/user');
             $user->login($username, $password);
             if ($user->getId()) {
+                $this->renewSession();
 
                 if (Mage::getSingleton('adminhtml/url')->useSecretKey()) {
                     Mage::getSingleton('adminhtml/url')->renewSecretUrls();
@@ -138,7 +139,11 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
             }
         }
         catch (Mage_Core_Exception $e) {
-            Mage::dispatchEvent('admin_session_user_login_failed', array('user_name'=>$username, 'exception' => $e));
+            $e->setMessage(
+                Mage::helper('adminhtml')->__('You did not sign in correctly or your account is temporarily disabled.')
+            );
+            Mage::dispatchEvent('admin_session_user_login_failed',
+                    array('user_name' => $username, 'exception' => $e));
             if ($request && !$request->getParam('messageSent')) {
                 Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
                 $request->setParam('messageSent', true);
diff --git app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php
new file mode 100644
index 0000000..bd57adb
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php
@@ -0,0 +1,52 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Admin
+ * @copyright Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/**
+ * Class Mage_Adminhtml_Block_Checkout_Formkey
+ */
+class Mage_Adminhtml_Block_Checkout_Formkey extends Mage_Adminhtml_Block_Template
+{
+    /**
+     * Check form key validation on checkout.
+     * If disabled, show notice.
+     *
+     * @return boolean
+     */
+    public function canShow()
+    {
+        return !Mage::getStoreConfigFlag('admin/security/validate_formkey_checkout');
+    }
+
+    /**
+     * Get url for edit Advanced -> Admin section
+     *
+     * @return string
+     */
+    public function getSecurityAdminUrl()
+    {
+        return Mage::helper("adminhtml")->getUrl('adminhtml/system_config/edit/section/admin');
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
index 54f9052..51e68fc 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
@@ -137,11 +137,11 @@ class Mage_Adminhtml_Block_Widget_Grid_Column_Filter_Date extends Mage_Adminhtml
         if (isset($value['locale'])) {
             if (!empty($value['from'])) {
                 $value['orig_from'] = $value['from'];
-                $value['from'] = $this->_convertDate($value['from'], $value['locale']);
+                $value['from'] = $this->_convertDate($this->stripTags($value['from']), $value['locale']);
             }
             if (!empty($value['to'])) {
                 $value['orig_to'] = $value['to'];
-                $value['to'] = $this->_convertDate($value['to'], $value['locale']);
+                $value['to'] = $this->_convertDate($this->stripTags($value['to']), $value['locale']);
             }
         }
         if (empty($value['from']) && empty($value['to'])) {
diff --git app/code/core/Mage/Adminhtml/Model/Config/Data.php app/code/core/Mage/Adminhtml/Model/Config/Data.php
index 48375f5..c3894c4 100644
--- app/code/core/Mage/Adminhtml/Model/Config/Data.php
+++ app/code/core/Mage/Adminhtml/Model/Config/Data.php
@@ -153,6 +153,9 @@ class Mage_Adminhtml_Model_Config_Data extends Varien_Object
                 if (is_object($fieldConfig)) {
                     $configPath = (string)$fieldConfig->config_path;
                     if (!empty($configPath) && strrpos($configPath, '/') > 0) {
+                        if (!Mage::getSingleton('admin/session')->isAllowed($configPath)) {
+                            Mage::throwException('Access denied.');
+                        }
                         // Extend old data with specified section group
                         $groupPath = substr($configPath, 0, strrpos($configPath, '/'));
                         if (!isset($oldConfigAdditionalGroups[$groupPath])) {
diff --git app/code/core/Mage/Adminhtml/controllers/IndexController.php app/code/core/Mage/Adminhtml/controllers/IndexController.php
index ae82c59..c977daf 100644
--- app/code/core/Mage/Adminhtml/controllers/IndexController.php
+++ app/code/core/Mage/Adminhtml/controllers/IndexController.php
@@ -71,8 +71,10 @@ class Mage_Adminhtml_IndexController extends Mage_Adminhtml_Controller_Action
 
     public function logoutAction()
     {
-        $auth = Mage::getSingleton('admin/session')->unsetAll();
+        $adminSession = Mage::getSingleton('admin/session');
+        $adminSession->unsetAll();
         Mage::getSingleton('adminhtml/session')->unsetAll();
+        $adminSession->getCookie()->delete($adminSession->getSessionName());
         Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('adminhtml')->__('You have logged out.'));
         $this->_redirect('*');
     }
diff --git app/code/core/Mage/Checkout/controllers/MultishippingController.php app/code/core/Mage/Checkout/controllers/MultishippingController.php
index d21ae38..763868d 100644
--- app/code/core/Mage/Checkout/controllers/MultishippingController.php
+++ app/code/core/Mage/Checkout/controllers/MultishippingController.php
@@ -224,6 +224,12 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
             $this->_redirect('*/multishipping_address/newShipping');
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            $this->_redirect('*/*/addresses');
+            return;
+        }
+
         try {
             if ($this->getRequest()->getParam('continue', false)) {
                 $this->_getCheckout()->setCollectRatesFlag(true);
@@ -330,6 +336,11 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
 
     public function shippingPostAction()
     {
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            $this->_redirect('*/*/shipping');
+            return;
+        }
+
         $shippingMethods = $this->getRequest()->getPost('shipping_method');
         try {
             Mage::dispatchEvent(
@@ -433,6 +444,11 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
             return $this;
         }
 
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            $this->_redirect('*/*/billing');
+            return;
+        }
+
         $this->_getState()->setActiveStep(Mage_Checkout_Model_Type_Multishipping_State::STEP_OVERVIEW);
 
         try {
diff --git app/code/core/Mage/Checkout/controllers/OnepageController.php app/code/core/Mage/Checkout/controllers/OnepageController.php
index be5bcf7..4ded8c9 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -303,6 +303,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
         if ($this->getRequest()->isPost()) {
             $method = $this->getRequest()->getPost('method');
             $result = $this->getOnepage()->saveCheckoutMethod($method);
@@ -318,6 +319,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
 //            $postData = $this->getRequest()->getPost('billing', array());
 //            $data = $this->_filterPostData($postData);
@@ -363,6 +369,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
             $data = $this->getRequest()->getPost('shipping', array());
             $customerAddressId = $this->getRequest()->getPost('shipping_address_id', false);
@@ -387,6 +398,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
             $data = $this->getRequest()->getPost('shipping_method', '');
             $result = $this->getOnepage()->saveShippingMethod($data);
@@ -417,6 +433,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         try {
             if (!$this->getRequest()->isPost()) {
                 $this->_ajaxRedirectResponse();
diff --git app/code/core/Mage/Checkout/etc/system.xml app/code/core/Mage/Checkout/etc/system.xml
index f784a4a..6015e20 100644
--- app/code/core/Mage/Checkout/etc/system.xml
+++ app/code/core/Mage/Checkout/etc/system.xml
@@ -222,5 +222,23 @@
                 </payment_failed>
             </groups>
         </checkout>
+        <admin>
+            <groups>
+                <security>
+                    <fields>
+                        <validate_formkey_checkout translate="label comment">
+                            <label>Enable Form Key Validation On Checkout</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>4</sort_order>
+                            <comment><![CDATA[<strong style="color:red">Important!</strong> Enabling this option means
+                            that your custom templates used in checkout process contain form_key output.
+                            Otherwise checkout may not work.]]></comment>
+                            <show_in_default>1</show_in_default>
+                        </validate_formkey_checkout>
+                    </fields>
+                </security>
+            </groups>
+        </admin>
     </sections>
 </config>
diff --git app/code/core/Mage/Core/Controller/Front/Action.php app/code/core/Mage/Core/Controller/Front/Action.php
index 2244690..f8ace79 100644
--- app/code/core/Mage/Core/Controller/Front/Action.php
+++ app/code/core/Mage/Core/Controller/Front/Action.php
@@ -34,6 +34,11 @@
 class Mage_Core_Controller_Front_Action extends Mage_Core_Controller_Varien_Action
 {
     /**
+     * Add secret key to url config path
+     */
+    const XML_CSRF_USE_FLAG_CONFIG_PATH   = 'system/csrf/use_form_key';
+
+    /**
      * Currently used area
      *
      * @var string
@@ -86,4 +91,38 @@ class Mage_Core_Controller_Front_Action extends Mage_Core_Controller_Varien_Acti
         array_unshift($args, $expr);
         return Mage::app()->getTranslator()->translate($args);
     }
+
+    /**
+     * Validate Form Key
+     *
+     * @return bool
+     */
+    protected function _validateFormKey()
+    {
+        $validated = true;
+        if ($this->_isFormKeyEnabled()) {
+            $validated = parent::_validateFormKey();
+        }
+        return $validated;
+    }
+
+    /**
+     * Check if form key validation is enabled.
+     *
+     * @return bool
+     */
+    protected function _isFormKeyEnabled()
+    {
+        return Mage::getStoreConfigFlag(self::XML_CSRF_USE_FLAG_CONFIG_PATH);
+    }
+
+    /**
+     * Check if form_key validation enabled on checkout process
+     *
+     * @return bool
+     */
+    protected function isFormkeyValidationOnCheckoutEnabled()
+    {
+        return Mage::getStoreConfigFlag('admin/security/validate_formkey_checkout');
+    }
 }
diff --git app/code/core/Mage/Core/Controller/Request/Http.php app/code/core/Mage/Core/Controller/Request/Http.php
index f82f4db..1a1909a 100644
--- app/code/core/Mage/Core/Controller/Request/Http.php
+++ app/code/core/Mage/Core/Controller/Request/Http.php
@@ -155,7 +155,10 @@ class Mage_Core_Controller_Request_Http extends Zend_Controller_Request_Http
             $baseUrl = $this->getBaseUrl();
             $pathInfo = substr($requestUri, strlen($baseUrl));
 
-            if ((null !== $baseUrl) && (false === $pathInfo)) {
+            if ($baseUrl && $pathInfo && (0 !== stripos($pathInfo, '/'))) {
+                $pathInfo = '';
+                $this->setActionName('noRoute');
+            } elseif ((null !== $baseUrl) && (false === $pathInfo)) {
                 $pathInfo = '';
             } elseif (null === $baseUrl) {
                 $pathInfo = $requestUri;
diff --git app/code/core/Mage/Core/Model/Session/Abstract.php app/code/core/Mage/Core/Model/Session/Abstract.php
index 946c100..8c6dd75 100644
--- app/code/core/Mage/Core/Model/Session/Abstract.php
+++ app/code/core/Mage/Core/Model/Session/Abstract.php
@@ -500,4 +500,18 @@ class Mage_Core_Model_Session_Abstract extends Mage_Core_Model_Session_Abstract_
         }
         return parent::getSessionSavePath();
     }
+
+    /**
+     * Renew session id and update session cookie
+     *
+     * @return Mage_Core_Model_Session_Abstract
+     */
+    public function renewSession()
+    {
+        $this->getCookie()->delete($this->getSessionName());
+        $this->regenerateSessionId();
+
+        return $this;
+    }
+
 }
diff --git app/code/core/Mage/Core/Model/Session/Abstract/Varien.php app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
index 233dec6..190ab54 100644
--- app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
+++ app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
@@ -356,13 +356,19 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
         $sessionData = $this->_data[self::VALIDATOR_KEY];
         $validatorData = $this->getValidatorData();
 
-        if ($this->useValidateRemoteAddr() && $sessionData[self::VALIDATOR_REMOTE_ADDR_KEY] != $validatorData[self::VALIDATOR_REMOTE_ADDR_KEY]) {
+        if ($this->useValidateRemoteAddr()
+                && $sessionData[self::VALIDATOR_REMOTE_ADDR_KEY] != $validatorData[self::VALIDATOR_REMOTE_ADDR_KEY]) {
             return false;
         }
-        if ($this->useValidateHttpVia() && $sessionData[self::VALIDATOR_HTTP_VIA_KEY] != $validatorData[self::VALIDATOR_HTTP_VIA_KEY]) {
+        if ($this->useValidateHttpVia()
+                && $sessionData[self::VALIDATOR_HTTP_VIA_KEY] != $validatorData[self::VALIDATOR_HTTP_VIA_KEY]) {
             return false;
         }
-        if ($this->useValidateHttpXForwardedFor() && $sessionData[self::VALIDATOR_HTTP_X_FORVARDED_FOR_KEY] != $validatorData[self::VALIDATOR_HTTP_X_FORVARDED_FOR_KEY]) {
+
+        $sessionValidateHttpXForwardedForKey = $sessionData[self::VALIDATOR_HTTP_X_FORVARDED_FOR_KEY];
+        $validatorValidateHttpXForwardedForKey = $validatorData[self::VALIDATOR_HTTP_X_FORVARDED_FOR_KEY];
+        if ($this->useValidateHttpXForwardedFor()
+            && $sessionValidateHttpXForwardedForKey != $validatorValidateHttpXForwardedForKey ) {
             return false;
         }
         if ($this->useValidateHttpUserAgent()
@@ -406,4 +412,15 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
 
         return $parts;
     }
+
+    /**
+     * Regenerate session Id
+     *
+     * @return Mage_Core_Model_Session_Abstract_Varien
+     */
+    public function regenerateSessionId()
+    {
+        session_regenerate_id(true);
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Core/Model/Session/Abstract/Zend.php app/code/core/Mage/Core/Model/Session/Abstract/Zend.php
index 8435c17..375ed45 100644
--- app/code/core/Mage/Core/Model/Session/Abstract/Zend.php
+++ app/code/core/Mage/Core/Model/Session/Abstract/Zend.php
@@ -162,4 +162,15 @@ abstract class Mage_Core_Model_Session_Abstract_Zend extends Varien_Object
         }
         return $this;
     }
+
+    /**
+     * Regenerate session Id
+     *
+     * @return Mage_Core_Model_Session_Abstract_Zend
+     */
+    public function regenerateSessionId()
+    {
+        Zend_Session::regenerateId();
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 070faa0..7db9706 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -216,6 +216,9 @@
         </dev>
 
         <system>
+            <csrf>
+                <use_form_key>1</use_form_key>
+            </csrf>
             <smtp>
                 <disable>0</disable>
                 <host>localhost</host>
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index 93a7abf..131a0e4 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -41,6 +41,29 @@
         </advanced>
     </tabs>
     <sections>
+        <system>
+            <groups>
+                <csrf translate="label" module="core">
+                    <label>CSRF protection</label>
+                    <frontend_type>text</frontend_type>
+                    <sort_order>0</sort_order>
+                    <show_in_default>1</show_in_default>
+                    <show_in_website>0</show_in_website>
+                    <show_in_store>0</show_in_store>
+                    <fields>
+                        <use_form_key translate="label">
+                            <label>Add Secret Key To Url</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>10</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </use_form_key>
+                    </fields>
+                </csrf>
+            </groups>
+        </system>
         <!--<web_track translate="label" module="core">
             <label>Web Tracking</label>
             <frontend_type>text</frontend_type>
diff --git app/code/core/Mage/Customer/Model/Session.php app/code/core/Mage/Customer/Model/Session.php
index a4fcb64..0a545a9 100644
--- app/code/core/Mage/Customer/Model/Session.php
+++ app/code/core/Mage/Customer/Model/Session.php
@@ -176,6 +176,7 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
      */
     public function login($username, $password)
     {
+        /** @var $customer Mage_Customer_Model_Customer */
         $customer = Mage::getModel('customer/customer')
             ->setWebsiteId(Mage::app()->getStore()->getWebsiteId());
 
@@ -189,6 +190,8 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
     public function setCustomerAsLoggedIn($customer)
     {
         $this->setCustomer($customer);
+        $this->renewSession();
+        Mage::getSingleton('core/session')->renewFormKey();
         Mage::dispatchEvent('customer_login', array('customer'=>$customer));
         return $this;
     }
@@ -219,6 +222,8 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
         if ($this->isLoggedIn()) {
             Mage::dispatchEvent('customer_logout', array('customer' => $this->getCustomer()) );
             $this->setId(null);
+            $this->getCookie()->delete($this->getSessionName());
+            Mage::getSingleton('core/session')->renewFormKey();
         }
         return $this;
     }
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index b0c738f..70531cc 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -329,7 +329,6 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             $url = $this->_getUrl('*/*/index', array('_secure' => true));
         } else {
             $session->setCustomerAsLoggedIn($customer);
-            $session->renewSession();
             $url = $this->_welcomeCustomer($customer);
         }
         $this->_redirectSuccess($url);
@@ -564,7 +563,6 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     throw new Exception($this->__('Failed to confirm customer account.'));
                 }
 
-                $session->renewSession();
                 // log in and send greeting email, then die happy
                 $session->setCustomerAsLoggedIn($customer);
                 $successUrl = $this->_welcomeCustomer($customer, true);
diff --git app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
index 00688df..8eca565 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
@@ -40,6 +40,9 @@ class Mage_Dataflow_Model_Convert_Adapter_Zend_Cache extends Mage_Dataflow_Model
         if (!$this->_resource) {
             $this->_resource = Zend_Cache::factory($this->getVar('frontend', 'Core'), $this->getVar('backend', 'File'));
         }
+        if ($this->_resource->getBackend() instanceof Zend_Cache_Backend_Static) {
+            throw new Exception(Mage::helper('dataflow')->__('Backend name "Static" not supported.'));
+        }
         return $this->_resource;
     }
 
diff --git app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
index 1dd8edc..b44e832 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
@@ -47,6 +47,18 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
 
     protected $_position;
 
+    /**
+     * Detect serialization of data
+     *
+     * @param mixed $data
+     * @return bool
+     */
+    protected function isSerialized($data)
+    {
+        $pattern = '/^a:\d+:\{(i:\d+;|s:\d+:\".+\";|N;|O:\d+:\"\w+\":\d+:\{\w:\d+:)+|^O:\d+:\"\w+\":\d+:\{s:\d+:\"/';
+        return (is_string($data) && preg_match($pattern, $data));
+    }
+
     public function getVar($key, $default=null)
     {
         if (!isset($this->_vars[$key]) || (!is_array($this->_vars[$key]) && strlen($this->_vars[$key]) == 0)) {
@@ -102,13 +114,45 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
 
     public function setData($data)
     {
-        if ($this->getProfile()) {
-            $this->getProfile()->getContainer()->setData($data);
+        if ($this->validateDataSerialized($data)) {
+            if ($this->getProfile()) {
+                $this->getProfile()->getContainer()->setData($data);
+            }
+
+            $this->_data = $data;
         }
-        $this->_data = $data;
+
         return $this;
     }
 
+    /**
+     * Validate serialized data
+     *
+     * @param mixed $data
+     * @return bool
+     */
+    public function validateDataSerialized($data = null)
+    {
+        if (is_null($data)) {
+            $data = $this->getData();
+        }
+
+        $result = true;
+        if ($this->isSerialized($data)) {
+            try {
+                $dataArray = Mage::helper('core/unserializeArray')->unserialize($data);
+            } catch (Exception $e) {
+                $result = false;
+                $this->addException(
+                    "Invalid data, expecting serialized array.",
+                    Mage_Dataflow_Model_Convert_Exception::FATAL
+                );
+            }
+        }
+
+        return $result;
+    }
+
     public function validateDataString($data=null)
     {
         if (is_null($data)) {
@@ -140,7 +184,10 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
             if (count($data)==0) {
                 return true;
             }
-            $this->addException("Invalid data type, expecting 2D grid array.", Mage_Dataflow_Model_Convert_Exception::FATAL);
+            $this->addException(
+                "Invalid data type, expecting 2D grid array.",
+                Mage_Dataflow_Model_Convert_Exception::FATAL
+            );
         }
         return true;
     }
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
index 87801d5..78fae11 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
@@ -77,8 +77,8 @@ class Mage_Dataflow_Model_Convert_Parser_Csv extends Mage_Dataflow_Model_Convert
         $batchIoAdapter = $this->getBatchModel()->getIoAdapter();
 
         if (Mage::app()->getRequest()->getParam('files')) {
-            $file = Mage::app()->getConfig()->getTempVarDir().'/import/'
-                . urldecode(Mage::app()->getRequest()->getParam('files'));
+            $file = Mage::app()->getConfig()->getTempVarDir() . '/import/'
+                . str_replace('../', '', urldecode(Mage::app()->getRequest()->getParam('files')));
             $this->_copy($file);
         }
 
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
index ed67a2a..b5a821d 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
@@ -78,8 +78,8 @@ class Mage_Dataflow_Model_Convert_Parser_Xml_Excel extends Mage_Dataflow_Model_C
         $batchIoAdapter = $this->getBatchModel()->getIoAdapter();
 
         if (Mage::app()->getRequest()->getParam('files')) {
-            $file = Mage::app()->getConfig()->getTempVarDir().'/import/'
-                . urldecode(Mage::app()->getRequest()->getParam('files'));
+            $file = Mage::app()->getConfig()->getTempVarDir() . '/import/'
+                . str_replace('../', '', urldecode(Mage::app()->getRequest()->getParam('files')));
             $this->_copy($file);
         }
 
diff --git app/code/core/Mage/Sales/Model/Quote/Item.php app/code/core/Mage/Sales/Model/Quote/Item.php
index 77dd48e..9d84b01 100644
--- app/code/core/Mage/Sales/Model/Quote/Item.php
+++ app/code/core/Mage/Sales/Model/Quote/Item.php
@@ -370,8 +370,9 @@ class Mage_Sales_Model_Quote_Item extends Mage_Sales_Model_Quote_Item_Abstract
                         /** @var Unserialize_Parser $parser */
                         $parser = Mage::helper('core/unserializeArray');
 
-                        $_itemOptionValue = $parser->unserialize($itemOptionValue);
-                        $_optionValue = $parser->unserialize($optionValue);
+                        $_itemOptionValue =
+                            is_numeric($itemOptionValue) ? $itemOptionValue : $parser->unserialize($itemOptionValue);
+                        $_optionValue = is_numeric($optionValue) ? $optionValue : $parser->unserialize($optionValue);
 
                         if (is_array($_itemOptionValue) && is_array($_optionValue)) {
                             $itemOptionValue = $_itemOptionValue;
diff --git app/code/core/Mage/Widget/Model/Widget/Instance.php app/code/core/Mage/Widget/Model/Widget/Instance.php
index 2d7b51e..0f2c78f 100644
--- app/code/core/Mage/Widget/Model/Widget/Instance.php
+++ app/code/core/Mage/Widget/Model/Widget/Instance.php
@@ -318,7 +318,11 @@ class Mage_Widget_Model_Widget_Instance extends Mage_Core_Model_Abstract
     public function getWidgetParameters()
     {
         if (is_string($this->getData('widget_parameters'))) {
-            return unserialize($this->getData('widget_parameters'));
+            try {
+                return Mage::helper('core/unserializeArray')->unserialize($this->getData('widget_parameters'));
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
         }
         return $this->getData('widget_parameters');
     }
diff --git app/design/adminhtml/default/default/layout/main.xml app/design/adminhtml/default/default/layout/main.xml
index 9210173..0dcb8ca 100644
--- app/design/adminhtml/default/default/layout/main.xml
+++ app/design/adminhtml/default/default/layout/main.xml
@@ -111,6 +111,7 @@ Default layout, loads most of the pages
                 <block type="adminhtml/notification_baseurl" name="notification_baseurl" as="notification_baseurl" template="notification/baseurl.phtml"></block>
                 <block type="adminhtml/cache_notifications" name="cache_notifications" template="system/cache/notifications.phtml"></block>
                 <block type="adminhtml/notification_survey" name="notification_survey" template="notification/survey.phtml"/>
+                <block type="adminhtml/checkout_formkey" name="checkout_formkey" as="checkout_formkey" template="notification/formkey.phtml"/>
             </block>
             <block type="adminhtml/widget_breadcrumbs" name="breadcrumbs" as="breadcrumbs"></block>
 
diff --git app/design/adminhtml/default/default/template/notification/formkey.phtml app/design/adminhtml/default/default/template/notification/formkey.phtml
new file mode 100644
index 0000000..3798465
--- /dev/null
+++ app/design/adminhtml/default/default/template/notification/formkey.phtml
@@ -0,0 +1,38 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Admin
+ * @copyright Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+/**
+ * @see Mage_Adminhtml_Block_Checkout_Formkey
+ */
+?>
+<?php if ($this->canShow()): ?>
+    <div class="notification-global notification-global-warning">
+        <strong style="color:red">Important: </strong>
+        <span>Formkey validation on checkout disabled. This may expose security risks.
+        We strongly recommend to Enable Form Key Validation On Checkout in
+        <a href="<?php echo $this->getSecurityAdminUrl(); ?>">Admin / Security Section</a>,
+        for protect your own checkout process. </span>
+    </div>
+<?php endif; ?>
diff --git app/design/adminhtml/default/default/template/page/head.phtml app/design/adminhtml/default/default/template/page/head.phtml
index 744adf3..3764dcf 100644
--- app/design/adminhtml/default/default/template/page/head.phtml
+++ app/design/adminhtml/default/default/template/page/head.phtml
@@ -8,7 +8,7 @@
     var BLANK_URL = '<?php echo $this->getJsUrl() ?>blank.html';
     var BLANK_IMG = '<?php echo $this->getJsUrl() ?>spacer.gif';
     var BASE_URL = '<?php echo $this->getUrl('*') ?>';
-    var SKIN_URL = '<?php echo $this->getSkinUrl() ?>';
+    var SKIN_URL = '<?php echo $this->jsQuoteEscape($this->getSkinUrl()) ?>';
     var FORM_KEY = '<?php echo $this->getFormKey() ?>';
 </script>
 
diff --git app/design/frontend/base/default/template/checkout/cart/shipping.phtml app/design/frontend/base/default/template/checkout/cart/shipping.phtml
index 77af444..c5acf5e 100644
--- app/design/frontend/base/default/template/checkout/cart/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/cart/shipping.phtml
@@ -113,6 +113,7 @@
             <div class="buttons-set">
                 <button type="submit" title="<?php echo $this->__('Update Total') ?>" class="button" name="do" value="<?php echo $this->__('Update Total') ?>"><span><span><?php echo $this->__('Update Total') ?></span></span></button>
             </div>
+            <?php echo $this->getBlockHtml('formkey') ?>
         </form>
         <?php endif; ?>
         <script type="text/javascript">
diff --git app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml
index fefd42f..352ddd6 100644
--- app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml
@@ -76,4 +76,5 @@
             <button type="submit" title="<?php echo $this->__('Continue to Shipping Information') ?>" class="button<?php if ($this->isContinueDisabled()):?> disabled<?php endif; ?>" onclick="$('can_continue_flag').value=1"<?php if ($this->isContinueDisabled()):?> disabled="disabled"<?php endif; ?>><span><span><?php echo $this->__('Continue to Shipping Information') ?></span></span></button>
         </div>
     </div>
+    <?php echo $this->getBlockHtml("formkey") ?>
 </form>
diff --git app/design/frontend/base/default/template/checkout/multishipping/billing.phtml app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
index e98e131..df084f5 100644
--- app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
@@ -91,6 +91,7 @@
             <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Shipping Information') ?></a></p>
             <button type="submit" title="<?php echo $this->__('Continue to Review Your Order') ?>" class="button"><span><span><?php echo $this->__('Continue to Review Your Order') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </form>
     <script type="text/javascript">
     //<![CDATA[
diff --git app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
index 825a72c..13fac10 100644
--- app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
@@ -125,5 +125,6 @@
             <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Select Addresses') ?></a></p>
             <button type="submit" title="<?php echo $this->__('Continue to Billing Information') ?>" class="button"><span><span><?php echo $this->__('Continue to Billing Information') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </form>
 </div>
diff --git app/design/frontend/base/default/template/checkout/onepage/billing.phtml app/design/frontend/base/default/template/checkout/onepage/billing.phtml
index dfe1787..fc11982 100644
--- app/design/frontend/base/default/template/checkout/onepage/billing.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/billing.phtml
@@ -188,6 +188,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
 <script type="text/javascript">
diff --git app/design/frontend/base/default/template/checkout/onepage/payment.phtml app/design/frontend/base/default/template/checkout/onepage/payment.phtml
index 81accb8..7b6b47e 100644
--- app/design/frontend/base/default/template/checkout/onepage/payment.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/payment.phtml
@@ -33,6 +33,7 @@
     <fieldset>
         <?php echo $this->getChildHtml('methods') ?>
     </fieldset>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <div class="tool-tip" id="payment-tool-tip" style="display:none;">
     <div class="btn-close"><a href="#" id="payment-tool-tip-close" title="<?php echo $this->__('Close') ?>"><?php echo $this->__('Close') ?></a></div>
diff --git app/design/frontend/base/default/template/checkout/onepage/shipping.phtml app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
index 2ea630a..c8b7226 100644
--- app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
@@ -139,6 +139,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
index a151042..ccf6943 100644
--- app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
@@ -43,4 +43,5 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
diff --git app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml
index c973789..683e31a 100644
--- app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml
+++ app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml
@@ -107,6 +107,7 @@
         <div class="buttons-set">
             <button type="submit" class="button" name="do" value="<?php echo $this->__('Update Total') ?>"><span><span><?php echo $this->__('Update Total') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </fieldset>
 </form>
 <?php endif; ?>
diff --git app/design/frontend/enterprise/default/template/checkout/multishipping/addresses.phtml app/design/frontend/enterprise/default/template/checkout/multishipping/addresses.phtml
index b307bb9..5fcc54b 100644
--- app/design/frontend/enterprise/default/template/checkout/multishipping/addresses.phtml
+++ app/design/frontend/enterprise/default/template/checkout/multishipping/addresses.phtml
@@ -75,5 +75,6 @@
         <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Shopping Cart') ?></a></p>
         <button type="submit" class="button<?php if ($this->isContinueDisabled()):?> disabled<?php endif; ?>" onclick="$('can_continue_flag').value=1"<?php if ($this->isContinueDisabled()):?> disabled="disabled"<?php endif; ?>><span><span><?php echo $this->__('Continue to Shipping Information') ?></span></span></button>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
diff --git app/design/frontend/enterprise/default/template/checkout/multishipping/billing.phtml app/design/frontend/enterprise/default/template/checkout/multishipping/billing.phtml
index d9026d4..e016c62 100644
--- app/design/frontend/enterprise/default/template/checkout/multishipping/billing.phtml
+++ app/design/frontend/enterprise/default/template/checkout/multishipping/billing.phtml
@@ -92,6 +92,7 @@
     <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Shipping Information') ?></a></p>
     <button type="submit" class="button"><span><span><?php echo $this->__('Continue to Review Your Order') ?></span></span></button>
 </div>
+<?php echo $this->getBlockHtml('formkey') ?>
 </form>
 </div>
 <script type="text/javascript">
diff --git app/design/frontend/enterprise/default/template/checkout/multishipping/shipping.phtml app/design/frontend/enterprise/default/template/checkout/multishipping/shipping.phtml
index fb892d9..dd8c4eb 100644
--- app/design/frontend/enterprise/default/template/checkout/multishipping/shipping.phtml
+++ app/design/frontend/enterprise/default/template/checkout/multishipping/shipping.phtml
@@ -116,5 +116,6 @@
         <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Select Addresses') ?></a></p>
         <button  class="button" type="submit"><span><span><?php echo $this->__('Continue to Billing Information') ?></span></span></button>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
diff --git app/design/frontend/enterprise/default/template/checkout/onepage/billing.phtml app/design/frontend/enterprise/default/template/checkout/onepage/billing.phtml
index 438ba5a..7809cc5 100644
--- app/design/frontend/enterprise/default/template/checkout/onepage/billing.phtml
+++ app/design/frontend/enterprise/default/template/checkout/onepage/billing.phtml
@@ -211,6 +211,7 @@
     </span>
 </div>
 <p class="required"><?php echo $this->__('* Required Fields') ?></p>
+<?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml
index 07c9b82..5e2add1 100644
--- app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml
+++ app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml
@@ -35,6 +35,7 @@
         <?php echo $this->getChildChildHtml('methods_additional', '', true, true) ?>
         <?php echo $this->getChildHtml('methods') ?>
     </fieldset>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <div class="tool-tip" id="payment-tool-tip" style="display:none;">
     <div class="btn-close"><a href="#" id="payment-tool-tip-close"><img src="<?php echo $this->getSkinUrl('images/btn_window_close.gif') ?>" alt="<?php echo $this->__('Close') ?>" title="<?php echo $this->__('Close') ?>" /></a></div>
diff --git app/design/frontend/enterprise/default/template/checkout/onepage/shipping.phtml app/design/frontend/enterprise/default/template/checkout/onepage/shipping.phtml
index f00dca4..af720ea 100644
--- app/design/frontend/enterprise/default/template/checkout/onepage/shipping.phtml
+++ app/design/frontend/enterprise/default/template/checkout/onepage/shipping.phtml
@@ -148,6 +148,7 @@
     <span id="shipping-please-wait" class="please-wait" style="display:none;"><img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="" class="v-middle" /> <?php echo $this->__('Loading next step...') ?></span>
 </div>
 <p class="required"><?php echo $this->__('* Required Fields') ?></p>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml
index d1c6bc1..55a6ce6 100644
--- app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml
+++ app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml
@@ -83,7 +83,7 @@
         } else {
             var elements = Form.getElements(this.form);
             for (var i=0; i<elements.length; i++) {
-                if (elements[i].name == 'payment[method]') {
+                if (elements[i].name == 'payment[method]' || elements[i].name == 'form_key') {
                     elements[i].disabled = false;
                 }
             }
diff --git app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml
index 304ab26..9ec624d 100644
--- app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml
+++ app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml
@@ -38,7 +38,7 @@
         <script type="text/javascript">
         //<![CDATA[
             Form.getElements('multishipping-billing-form').each(function(elem){
-                if (elem.name == 'payment[method]' && elem.value == 'free') {
+                if ((elem.name == 'payment[method]' && elem.value == 'free') || elements[i].name == 'form_key') {
                     elem.checked = true;
                     elem.disabled = false;
                     elem.parentNode.show();
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index ad3bdd2..439d7f4 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -1135,3 +1135,5 @@
 "to","to"
 "website(%s) scope","website(%s) scope"
 "{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>.","{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>."
+"You did not sign in correctly or your account is temporarily disabled.","You did not sign in correctly or your account is temporarily disabled."
+"Symlinks are enabled. This may expose security risks. We strongly recommend to disable them.","Symlinks are enabled. This may expose security risks. We strongly recommend to disable them."
diff --git app/locale/en_US/Mage_Dataflow.csv app/locale/en_US/Mage_Dataflow.csv
index 1de3305..0e4ba0f 100644
--- app/locale/en_US/Mage_Dataflow.csv
+++ app/locale/en_US/Mage_Dataflow.csv
@@ -30,3 +30,4 @@
 "hours","hours"
 "minute","minute"
 "minutes","minutes"
+"Backend name "Static" not supported.","Backend name "Static" not supported."
diff --git js/varien/payment.js js/varien/payment.js
index 185ac40..59e3ad2 100644
--- js/varien/payment.js
+++ js/varien/payment.js
@@ -31,7 +31,7 @@ paymentForm.prototype = {
 
         var method = null;
         for (var i=0; i<elements.length; i++) {
-            if (elements[i].name=='payment[method]') {
+            if (elements[i].name=='payment[method]' || elements[i].name=='form_key') {
                 if (elements[i].checked) {
                     method = elements[i].value;
                 }
diff --git skin/frontend/base/default/js/opcheckout.js skin/frontend/base/default/js/opcheckout.js
index f02d6a9..f7f9713 100644
--- skin/frontend/base/default/js/opcheckout.js
+++ skin/frontend/base/default/js/opcheckout.js
@@ -635,7 +635,7 @@ Payment.prototype = {
         }
         var method = null;
         for (var i=0; i<elements.length; i++) {
-            if (elements[i].name=='payment[method]') {
+            if (elements[i].name=='payment[method]' || elements[i].name == 'form_key') {
                 if (elements[i].checked) {
                     method = elements[i].value;
                 }
diff --git skin/frontend/enterprise/default/js/opcheckout.js skin/frontend/enterprise/default/js/opcheckout.js
index c1fd22d..dd8f4ba 100644
--- skin/frontend/enterprise/default/js/opcheckout.js
+++ skin/frontend/enterprise/default/js/opcheckout.js
@@ -31,7 +31,7 @@ Checkout.prototype = {
         this.saveMethodUrl = urls.saveMethod;
         this.failureUrl = urls.failure;
         this.billingForm = false;
-        this.shippingForm= false;
+        this.shippingForm = false;
         this.syncBillingShipping = false;
         this.method = '';
         this.payment = '';
@@ -44,7 +44,7 @@ Checkout.prototype = {
     },
 
     ajaxFailure: function(){
-        location.href = this.failureUrl;
+        location.href = encodeURI(this.failureUrl);
     },
 
     reloadProgressBlock: function(){
@@ -52,7 +52,7 @@ Checkout.prototype = {
     },
 
     reloadReviewBlock: function(){
-        var updater = new Ajax.Updater('checkout-review-load', this.reviewUrl, {method: 'get', onFailure: this.ajaxFailure.bind(this)});
+        new Ajax.Updater('checkout-review-load', this.reviewUrl, {method: 'get', onFailure: this.ajaxFailure.bind(this)});
     },
 
     _disableEnableAll: function(element, isDisabled) {
@@ -64,17 +64,18 @@ Checkout.prototype = {
     },
 
     setLoadWaiting: function(step, keepDisabled) {
+        var container;
         if (step) {
             if (this.loadWaiting) {
                 this.setLoadWaiting(false);
             }
-            var container = $(step+'-buttons-container');
+            container = $(step + '-buttons-container');
             container.setStyle({opacity:.8});
             this._disableEnableAll(container, true);
             Element.show(step+'-please-wait');
         } else {
             if (this.loadWaiting) {
-                var container = $(this.loadWaiting+'-buttons-container');
+                container = $(this.loadWaiting + '-buttons-container');
                 var isDisabled = (keepDisabled ? true : false);
                 if (!isDisabled) {
                     container.setStyle({opacity:1});
@@ -96,7 +97,7 @@ Checkout.prototype = {
     setMethod: function(){
         if ($('login:guest') && $('login:guest').checked) {
             this.method = 'guest';
-            var request = new Ajax.Request(
+            new Ajax.Request(
                 this.saveMethodUrl,
                 {method: 'post', onFailure: this.ajaxFailure.bind(this), parameters: {method:'guest'}}
             );
@@ -105,7 +106,7 @@ Checkout.prototype = {
         }
         else if($('login:register') && ($('login:register').checked || $('login:register').type == 'hidden')) {
             this.method = 'register';
-            var request = new Ajax.Request(
+            new Ajax.Request(
                 this.saveMethodUrl,
                 {method: 'post', onFailure: this.ajaxFailure.bind(this), parameters: {method:'register'}}
             );
@@ -201,7 +202,7 @@ Checkout.prototype = {
             return true;
         }
         if (response.redirect) {
-            location.href = response.redirect;
+            location.href = encodeURI(response.redirect);
             return true;
         }
         return false;
@@ -225,7 +226,7 @@ Billing.prototype = {
 
     setAddress: function(addressId){
         if (addressId) {
-            request = new Ajax.Request(
+            new Ajax.Request(
                 this.addressUrl+addressId,
                 {method:'get', onSuccess: this.onAddressLoad, onFailure: checkout.ajaxFailure.bind(checkout)}
             );
@@ -252,25 +253,19 @@ Billing.prototype = {
     },
 
     fillForm: function(transport){
-        var elementValues = {};
-        if (transport && transport.responseText){
-            try{
-                elementValues = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                elementValues = {};
-            }
-        }
-        else{
+        var elementValues = transport.responseJSON || transport.responseText.evalJSON(true) || {};
+        if (!transport && !Object.keys(elementValues).length){
             this.resetSelectedAddress();
         }
-        arrElements = Form.getElements(this.form);
+        var arrElements = Form.getElements(this.form);
         for (var elemIndex in arrElements) {
-            if (arrElements[elemIndex].id) {
-                var fieldName = arrElements[elemIndex].id.replace(/^billing:/, '');
-                arrElements[elemIndex].value = elementValues[fieldName] ? elementValues[fieldName] : '';
-                if (fieldName == 'country_id' && billingForm){
-                    billingForm.elementChildLoad(arrElements[elemIndex]);
+            if (arrElements.hasOwnProperty(elemIndex)) {
+                if (arrElements[elemIndex].id) {
+                    var fieldName = arrElements[elemIndex].id.replace(/^billing:/, '');
+                    arrElements[elemIndex].value = elementValues[fieldName] ? elementValues[fieldName] : '';
+                    if (fieldName == 'country_id' && billingForm){
+                        billingForm.elementChildLoad(arrElements[elemIndex]);
+                    }
                 }
             }
         }
@@ -291,7 +286,7 @@ Billing.prototype = {
 //                $('billing:use_for_shipping').value=1;
 //            }
 
-            var request = new Ajax.Request(
+            new Ajax.Request(
                 this.saveUrl,
                 {
                     method: 'post',
@@ -313,32 +308,30 @@ Billing.prototype = {
         There are 3 options: error, redirect or html with shipping options.
     */
     nextStep: function(transport){
-        if (transport && transport.responseText){
-            try{
-                response = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                response = {};
-            }
-        }
+        var response = transport.responseJSON || transport.responseText.evalJSON(true) || {};
 
         if (response.error){
-            if ((typeof response.message) == 'string') {
-                alert(response.message);
+            if (Object.isString(response.message)) {
+                alert(response.message.stripTags().toString());
             } else {
                 if (window.billingRegionUpdater) {
                     billingRegionUpdater.update();
                 }
 
-                alert(response.message.join("\n"));
+                var msg = response.message;
+                if (Object.isArray(msg)) {
+                    alert(msg.join("\n"));
+                }
+                alert(msg.stripTags().toString());
             }
 
             return false;
         }
 
         checkout.setStepResponse(response);
-
-        payment.initWhatIsCvvListeners();
+        if (payment) {
+            payment.initWhatIsCvvListeners();
+        }
 
         // DELETE
         //alert('error: ' + response.error + ' / redirect: ' + response.redirect + ' / shipping_methods_html: ' + response.shipping_methods_html);
@@ -365,7 +358,7 @@ Shipping.prototype = {
 
     setAddress: function(addressId){
         if (addressId) {
-            request = new Ajax.Request(
+            new Ajax.Request(
                 this.addressUrl+addressId,
                 {method:'get', onSuccess: this.onAddressLoad, onFailure: checkout.ajaxFailure.bind(checkout)}
             );
@@ -393,25 +386,19 @@ Shipping.prototype = {
     },
 
     fillForm: function(transport){
-        var elementValues = {};
-        if (transport && transport.responseText){
-            try{
-                elementValues = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                elementValues = {};
-            }
-        }
-        else{
+        var elementValues = transport.responseJSON || transport.responseText.evalJSON(true) || {};
+        if (!transport && !Object.keys(elementValues).length) {
             this.resetSelectedAddress();
         }
-        arrElements = Form.getElements(this.form);
+        var arrElements = Form.getElements(this.form);
         for (var elemIndex in arrElements) {
-            if (arrElements[elemIndex].id) {
-                var fieldName = arrElements[elemIndex].id.replace(/^shipping:/, '');
-                arrElements[elemIndex].value = elementValues[fieldName] ? elementValues[fieldName] : '';
-                if (fieldName == 'country_id' && shippingForm){
-                    shippingForm.elementChildLoad(arrElements[elemIndex]);
+            if (arrElements.hasOwnProperty(elemIndex)) {
+                if (arrElements[elemIndex].id) {
+                    var fieldName = arrElements[elemIndex].id.replace(/^shipping:/, '');
+                    arrElements[elemIndex].value = elementValues[fieldName] ? elementValues[fieldName] : '';
+                    if (fieldName == 'country_id' && shippingForm){
+                        shippingForm.elementChildLoad(arrElements[elemIndex]);
+                    }
                 }
             }
         }
@@ -458,7 +445,7 @@ Shipping.prototype = {
         var validator = new Validation(this.form);
         if (validator.validate()) {
             checkout.setLoadWaiting('shipping');
-            var request = new Ajax.Request(
+            new Ajax.Request(
                 this.saveUrl,
                 {
                     method:'post',
@@ -471,27 +458,25 @@ Shipping.prototype = {
         }
     },
 
-    resetLoadWaiting: function(transport){
+    resetLoadWaiting: function(){
         checkout.setLoadWaiting(false);
     },
 
     nextStep: function(transport){
-        if (transport && transport.responseText){
-            try{
-                response = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                response = {};
-            }
-        }
+        var response = transport.responseJSON || transport.responseText.evalJSON(true) || {};
+
         if (response.error){
-            if ((typeof response.message) == 'string') {
-                alert(response.message);
+            if (Object.isString(response.message)) {
+                alert(response.message.stripTags().toString());
             } else {
                 if (window.shippingRegionUpdater) {
                     shippingRegionUpdater.update();
                 }
-                alert(response.message.join("\n"));
+                var msg = response.message;
+                if (Object.isArray(msg)) {
+                    alert(msg.join("\n"));
+                }
+                alert(msg.stripTags().toString());
             }
 
             return false;
@@ -549,7 +534,7 @@ ShippingMethod.prototype = {
         if (checkout.loadWaiting!=false) return;
         if (this.validate()) {
             checkout.setLoadWaiting('shipping-method');
-            var request = new Ajax.Request(
+            new Ajax.Request(
                 this.saveUrl,
                 {
                     method:'post',
@@ -567,17 +552,10 @@ ShippingMethod.prototype = {
     },
 
     nextStep: function(transport){
-        if (transport && transport.responseText){
-            try{
-                response = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                response = {};
-            }
-        }
+        var response = transport.responseJSON || transport.responseText.evalJSON(true) || {};
 
         if (response.error) {
-            alert(response.message);
+            alert(response.message.stripTags().toString());
             return false;
         }
 
@@ -637,7 +615,7 @@ Payment.prototype = {
         var elements = Form.getElements(this.form);
         var method = null;
         for (var i=0; i<elements.length; i++) {
-            if (elements[i].name=='payment[method]') {
+            if (elements[i].name=='payment[method]' || elements[i].name=='form_key') {
                 if (elements[i].checked) {
                     method = elements[i].value;
                 }
@@ -748,7 +726,7 @@ Payment.prototype = {
         }
         if (this.validate() && this.validator.validate()) {
             checkout.setLoadWaiting('payment');
-            var request = new Ajax.Request(
+            new Ajax.Request(
                 this.saveUrl,
                 {
                     method:'post',
@@ -766,14 +744,8 @@ Payment.prototype = {
     },
 
     nextStep: function(transport){
-        if (transport && transport.responseText){
-            try{
-                response = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                response = {};
-            }
-        }
+        var response = transport.responseJSON || transport.responseText.evalJSON(true) || {};
+
         /*
         * if there is an error in payment, need to show error message
         */
@@ -788,7 +760,7 @@ Payment.prototype = {
                 }
                 return;
             }
-            alert(response.error);
+            alert(response.error.stripTags().toString());
             return;
         }
 
@@ -822,7 +794,7 @@ Review.prototype = {
             params += '&'+Form.serialize(this.agreementsForm);
         }
         params.save = true;
-        var request = new Ajax.Request(
+        new Ajax.Request(
             this.saveUrl,
             {
                 method:'post',
@@ -839,25 +811,22 @@ Review.prototype = {
     },
 
     nextStep: function(transport){
-        if (transport && transport.responseText) {
-            try{
-                response = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                response = {};
-            }
+        if (transport) {
+            var response = transport.responseJSON || transport.responseText.evalJSON(true) || {};
+
             if (response.redirect) {
-                location.href = response.redirect;
+                this.isSuccess = true;
+                location.href = encodeURI(response.redirect);
                 return;
             }
             if (response.success) {
                 this.isSuccess = true;
-                window.location=this.successUrl;
+                window.location = encodeURI(this.successUrl);
             }
             else{
                 var msg = response.error_messages;
-                if (typeof(msg)=='object') {
-                    msg = msg.join("\n");
+                if (Object.isArray(msg)) {
+                    msg = msg.join("\n").stripTags().toString();
                 }
                 alert(msg);
             }
