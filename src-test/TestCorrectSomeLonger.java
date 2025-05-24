import static org.junit.Assert.*;

import org.junit.Test;

public class TestCorrectSomeLonger {

	@Test
	public void test() {
		StringFinder a = new StringFinder(new Secret("ABCDEFG"));
		
		// correct string
		assertEquals(7,a.getGoal().evaluate("12CD34567"));
	}

}
