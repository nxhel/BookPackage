-- SET SERVEROUTPUT ON;
CREATE OR REPLACE PACKAGE book_package AS 
    FUNCTION get_price_after_tax(book_isbn books.isbn%TYPE)RETURN NUMBER ;
    TYPE customer_type_array IS VARRAY(100) OF ORDERS.CUSTOMER#%TYPE;
    PROCEDURE show_purchases ;
    PROCEDURE rename_category (book_category books.category%TYPE, book_newCategoryName books.category%TYPE);
    category_not_found EXCEPTION;
    category_too_long EXCEPTION;
    PROCEDURE add_publisher (publisher_name publisher.name%TYPE, publisher_contact publisher.contact%TYPE, publisher_phone publisher.phone%TYPE); 
    publisher_already_exists EXCEPTION;
END book_package;
/
CREATE OR REPLACE PACKAGE BODY book_package AS
 PROCEDURE add_publisher(
    publisher_name publisher.name%TYPE,
    publisher_contact publisher.contact%TYPE,
    publisher_phone publisher.phone%TYPE
  ) AS
    publisher_id publisher.pubid%TYPE;
    publisher_newId publisher.pubid%TYPE;
       
  BEGIN
    -- Check if a publisher with the same name and phone already exists
    
    SELECT pubid INTO publisher_id FROM PUBLISHER WHERE name = publisher_name AND phone = publisher_phone;
    
    IF publisher_id IS NOT NULL THEN
      RAISE publisher_already_exists;
    END IF;
    
    EXCEPTION
    
     WHEN NO_DATA_FOUND THEN
        -- If no data found, insert the new publisher
        SELECT COUNT(pubid) INTO publisher_newId FROM PUBLISHER;
        INSERT INTO PUBLISHER (pubid, name, contact, phone)
            VALUES (publisher_newId + 1, publisher_name, publisher_contact, publisher_phone);
        COMMIT;  
  END add_publisher;
--INTERNAL FUNCTION THAT IS NOT MENTIONED IN THE HEADER
/* PROCEDURE add_publisher (publisher_name publisher.name%TYPE, publisher_contact publisher.contact%TYPE, publisher_phone publisher.phone%TYPE)
    AS
       publisher_id publisher.pubid%TYPE;
       publisher_newId publisher.pubid%TYPE;
       
    BEGIN
        
        SELECT pubid INTO publisher_id FROM PUBLISHER WHERE  ( (name=publisher_name) AND (phone=publisher_phone);
        
        IF publisher_id IS NOT NULL THEN
            RAISE publisher_already_exists;
        ELSE 
        SELECT COUNT(pubid) INTO publisher_newId FROM PUBLISHER;
        INSERT INTO PUBLISHER (pubid,name,contact, phone)
            VALUES ((publisher_newId)+1),publisher_name,publisher_contact, publisher_phone);
            COMMIT;
        END IF;      
    END add_publisher;
*/
-------------------------------------------------------------------------------
PROCEDURE rename_category ( book_category books.category%TYPE, book_newCategoryName books.category%TYPE)
AS
category_match books.category%TYPE;
    BEGIN
        
        SELECT COUNT(*) INTO category_match FROM BOOKS WHERE category=book_category;
        
        IF category_match=0 THEN 
            RAISE category_not_found;
        END IF;
        
         IF LENGTHB(book_newCategoryName) > 12 THEN 
            RAISE category_too_long;
        END IF;
        
        UPDATE BOOKS
        SET category =  book_newCategoryName
        WHERE category = book_category;
        
        --USED SQLNOTFOUND TO CHECK IF A SQL STATEMENT HAS AFFECTED ANY ROW
         --IF SQL%NOTFOUND THEN
          --  RAISE category_too_long;
         --END IF;
         
        EXCEPTION
            WHEN no_data_found THEN
                RAISE category_not_found;
END rename_category  ;
-------------------------------------------------------------------------------
FUNCTION price_after_discount(book_isbn  books.isbn%TYPE)
    RETURN NUMBER IS
    bookPriceAfterDicsount NUMBER;
    bookDiscount NUMBER;
    BEGIN
        SELECT RETAIL INTO bookPriceAfterDicsount FROM books  WHERE isbn=book_isbn;
        SELECT DISCOUNT INTO bookDiscount FROM books  WHERE isbn=book_isbn;
        --POSSIBLE SOLUTION 
        --SELECT (RETAIL-DISCOUNT)  INTO bookPriceAfterDicsount FROM BOOKS WHERE isbn=book_isbn;
        bookPriceAfterDicsount:=bookPriceAfterDicsount-bookDiscount;
        RETURN bookPriceAfterDicsount;
    END price_after_discount;
 ------------------------------------------------------------------------------     
FUNCTION get_price_after_tax(book_isbn books.isbn%TYPE)
    RETURN NUMBER IS
    bookPriceAfterTax NUMBER;
    bookPriceAfterDiscount NUMBER; 
    
    BEGIN 
        -- do not need pakcage name since we are inside
        bookPriceAfterDiscount :=  price_after_discount(book_isbn);
        bookPriceAfterTax:= bookPriceAfterDiscount *1.15;
        RETURN bookPriceAfterTax;
    END get_price_after_tax;
------------------------------------------------------------------------------  
    
FUNCTION book_purchasers (book_isbn books.isbn%TYPE) RETURN customer_type_array
    IS customerarray customer_type_array;
        BEGIN
            SELECT customer# BULK COLLECT INTO customerarray
            FROM ORDERS o
            INNER JOIN ORDERITEMS USING (ORDER#)
            WHERE ORDERITEMS.isbn=book_isbn;
            return (customerarray);
        END book_purchasers;
------------------------------------------------------------------------------      
PROCEDURE show_purchases AS
    procedureCustomer customer_type_array ;
    customer_firstName  VARCHAR2(30);
    customer_lastName  VARCHAR2(30);
BEGIN
    FOR theBook IN (SELECT DISTINCT isbn, title FROM BOOKS) 
    LOOP
        procedureCustomer := book_purchasers(theBook.isbn);
        DBMS_OUTPUT.PUT('ISBN :' || theBook.isbn || '  ' || ' TITLE : ' || theBook.title || '  CUSTOMERS : ');
        
        FOR i IN 1..procedureCustomer.COUNT 
        LOOP
            
            SELECT firstname
            INTO customer_firstName  FROM customers c
            WHERE customer# = procedureCustomer(i);
            
            SELECT lastname
            INTO customer_lastName FROM customers 
            WHERE customer# = procedureCustomer(i);
            
            DBMS_OUTPUT.PUT( ' ' || customer_firstName  || ' ' || customer_lastName || ', ');
        END LOOP;
        DBMS_OUTPUT.PUT_LINE(' ');
    END LOOP;
END show_purchases;
END book_package ;
/
/*
DECLARE
   findPrice NUMBER(5,2);
   findPrice2 NUMBER(5,2);

BEGIN
  findPrice:= book_package.get_price_after_tax('4981341710');
    dbms_output.put_line('Final Price of Bulding a Car with Toothpick: '|| findPrice || ' $');
  findPrice2:= book_package.get_price_after_tax('3957136468');
    dbms_output.put_line('Final Price of Holy Grail of Oracle: '||findPrice2 ||' $');  
   book_package.show_purchases;
END;
/
*/
DECLARE
BEGIN
    --book_package.add_publisher('Dawson Printing','John Smith','111-555-2233');
    book_package.add_publisher('PUBLISH OUR WAY', 'Jane Tomlin', '010-410-0010');
    
     EXCEPTION
        WHEN book_package.publisher_already_exists THEN 
           dbms_output.put_line( 'PUBLISHER ALREADY EXISTS' );
END;
/
DECLARE
BEGIN
    book_package.add_publisher('Dawson Printing','John Smith','111-555-2233');
     EXCEPTION
        WHEN book_package.publisher_already_exists THEN 
           dbms_output.put_line( 'PUBLISHER ALREADY EXISTS' );
END;
/

DECLARE
BEGIN
    book_package.rename_category('COMPUTER','Computer-Science');
        EXCEPTION
        WHEN book_package.category_not_found THEN 
            dbms_output.put_line( 'NO CATEGORY FOUND' );
        WHEN book_package.category_too_long THEN 
            dbms_output.put_line( 'NEW CATEGORY TOO LONG' );         
END;
/
DECLARE
BEGIN
    book_package.rename_category('Teaching','Education');
        EXCEPTION
        WHEN book_package.category_not_found THEN 
            dbms_output.put_line( 'NO CATEGORY FOUND' );
        WHEN book_package.category_too_long THEN 
            dbms_output.put_line( 'NEW CATEGORY TOO LONG' );         
END;


        
        
