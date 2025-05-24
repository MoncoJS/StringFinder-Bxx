import static org.junit.Assert.*;

import org.junit.Test;

public class TestCorrectSomeShorter {

	@Test
	public void test() {
		StringFinder a = new StringFinder(new Secret("ABCDEFG"));
		
		// correct string
		assertEquals(5,a.getGoal().evaluate("ABBBBB"));
	}

}
